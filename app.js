/* ============================================================
   Afzal Opportunities — Admin Panel logic
   ------------------------------------------------------------
   Static single-page admin app. No build step.
   Uses the Firebase JS compat SDKs (v10) loaded in index.html.

   Views: login / dashboard (Published|Drafts|Archived|Expired)
          / editor (create & edit with live preview).

   SECURITY NOTE: hiding buttons or views in this panel is NOT the
   security boundary. Firestore rules (firestore.rules) and Storage
   rules (storage.rules) enforce admin-only writes server-side via the
   /admins/{uid} document check. Every write below will be REJECTED by
   the backend if the signed-in user is not an admin, no matter what
   the UI shows.
   ============================================================ */

/* ------------------------------------------------------------------
   FIREBASE CONFIG — REPLACE WITH YOUR FIREBASE CONFIG
   ------------------------------------------------------------------
   1. Go to the Firebase Console -> your project -> Project settings.
   2. Under "Your apps", register/add a Web app ("</>" icon).
   3. Copy the firebaseConfig object from the console and paste it here,
      replacing the placeholder values below.

   Example:
     const FIREBASE_CONFIG = {
       apiKey: "AIzaSy...",
       authDomain: "afzal-opportunities.firebaseapp.com",
       projectId: "afzal-opportunities",
       storageBucket: "afzal-opportunities.appspot.com",
       messagingSenderId: "1234567890",
       appId: "1:1234567890:web:abcdef..."
     };

   Full walkthrough: see docs/firebase-setup.md
   ------------------------------------------------------------------ */
const FIREBASE_CONFIG = {
  apiKey: "AIzaSyBJ2CaZHdCkHr9C815VQTJU3bRvi-OLJz4",
  authDomain: "afzal-opportunities.firebaseapp.com",
  projectId: "afzal-opportunities",
  storageBucket: "afzal-opportunities.firebasestorage.app",
  messagingSenderId: "727260702840",
  // appId is intentionally omitted: it is optional in the Firebase JS SDK and
  // only used by Installations-backed features (FCM/Analytics/Remote Config),
  // which this panel does not use. Auth + Firestore + Storage work with the
  // project-level values above. If you later register a Web app in the
  // Firebase console (Project settings -> Your apps -> </>), you may paste
  // its appId here, but it is not required.
};

/* ---------------- Constants ---------------- */
const CATEGORIES = ["jobs", "scholarships", "admissions", "other"];
const CATEGORY_LABELS = {
  jobs: "Jobs",
  scholarships: "Scholarships",
  admissions: "Admissions",
  other: "Other",
};
const POSTER_MAX_BYTES = 5 * 1024 * 1024; // 5 MB — mirrored by storage.rules
const POSTER_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/; // YYYY-MM-DD

/* ---------------- Small DOM helpers ---------------- */
const $ = (id) => document.getElementById(id);
const esc = (s) =>
  String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");

/* =================================================================
   Deadline semantics (JS mirror of the app's logic)
   -----------------------------------------------------------------
   Asia/Karachi is a FIXED UTC+5 offset (no DST). A lastDate of
   "YYYY-MM-DD" keeps the ad ACTIVE through 23:59:59 PKT on that day.

   Labels:
     no lastDate                 -> "LAST DATE NOT SPECIFIED"
     lastDate before today (PKT) -> "EXPIRED"
     lastDate == today (PKT)     -> "LAST DATE TODAY"
     lastDate == tomorrow (PKT)  -> "CLOSING TOMORROW"
     2..7 days away              -> "CLOSING SOON"
     > 7 days away               -> "N DAYS LEFT"
   A "NEW" badge is shown when publishedAt is within the last 72 hours.
   ================================================================= */

/** Today's date as "YYYY-MM-DD" in Asia/Karachi (UTC+5 fixed). */
function todayPKT() {
  const now = new Date();
  const pkt = new Date(now.getTime() + 5 * 60 * 60 * 1000); // shift to UTC+5
  const y = pkt.getUTCFullYear();
  const m = String(pkt.getUTCMonth() + 1).padStart(2, "0");
  const d = String(pkt.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Whole days from today (PKT) to a "YYYY-MM-DD" lastDate. */
function daysUntilPKT(lastDate) {
  const today = todayPKT();
  const t = Date.parse(today + "T00:00:00Z");
  const l = Date.parse(lastDate + "T00:00:00Z");
  return Math.round((l - t) / 86400000);
}

/** Deadline label for an advertisement. Returns { text, tone }.
    tone is one of: "neutral" | "fine" | "soon" | "hot" | "expired". */
function deadlineLabel(ad) {
  if (!ad.lastDate) return { text: "LAST DATE NOT SPECIFIED", tone: "neutral" };
  const days = daysUntilPKT(ad.lastDate);
  if (days < 0) return { text: "EXPIRED", tone: "expired" };
  if (days === 0) return { text: "LAST DATE TODAY", tone: "hot" };
  if (days === 1) return { text: "CLOSING TOMORROW", tone: "hot" };
  if (days <= 7) return { text: "CLOSING SOON", tone: "soon" };
  return { text: `${days} DAYS LEFT`, tone: "fine" };
}

/** True when the ad was published within the last 72 hours. */
function isNewAd(ad) {
  if (!ad.publishedAt) return false;
  const ts = ad.publishedAt.toDate ? ad.publishedAt.toDate() : new Date(ad.publishedAt);
  return Date.now() - ts.getTime() < 72 * 60 * 60 * 1000;
}

/** Format a "YYYY-MM-DD" PKT date for display, e.g. "25 Oct 2026". */
function formatPKTDate(yyyyMmDd) {
  if (!yyyyMmDd || !DATE_RE.test(yyyyMmDd)) return "";
  const [y, m, d] = yyyyMmDd.split("-").map(Number);
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return `${d} ${months[m - 1]} ${y}`;
}

/* ---------------- Toast notifications ---------------- */
function toast(message, kind = "success") {
  const el = document.createElement("div");
  el.className = `toast ${kind}`;
  el.textContent = message;
  $("toast-wrap").appendChild(el);
  setTimeout(() => el.remove(), 4200);
}

/* ---------------- Confirm dialog ---------------- */
let confirmResolve = null;
function confirmDialog(title, message, okLabel = "Confirm") {
  $("confirm-title").textContent = title;
  $("confirm-message").textContent = message;
  $("confirm-ok").textContent = okLabel;
  $("confirm-overlay").hidden = false;
  return new Promise((resolve) => {
    confirmResolve = resolve;
  });
}
$("confirm-cancel").addEventListener("click", () => {
  $("confirm-overlay").hidden = true;
  $("confirm-custom").innerHTML = "";
  $("confirm-custom").hidden = true;
  confirmResolve && confirmResolve(false);
  confirmResolve = null;
});
$("confirm-ok").addEventListener("click", () => {
  $("confirm-overlay").hidden = true;
  $("confirm-custom").innerHTML = "";
  $("confirm-custom").hidden = true;
  confirmResolve && confirmResolve(true);
  confirmResolve = null;
});

/* =================================================================
   Firebase initialization
   ================================================================= */
let auth, db, storage;

function configLooksPlaceholder(cfg) {
  return Object.values(cfg).some((v) => String(v).includes("REPLACE_WITH"));
}

function initFirebase() {
  firebase.initializeApp(FIREBASE_CONFIG);
  auth = firebase.auth();
  db = firebase.firestore();
  storage = firebase.storage();
}

/* =================================================================
   View routing (simple JS view switching)
   ================================================================= */
const VIEWS = ["view-login", "view-dashboard", "view-editor", "view-teaching"];
function showView(id) {
  VIEWS.forEach((v) => {
    $(v).hidden = v !== id;
  });
  window.scrollTo(0, 0);
}

/* =================================================================
   Auth — sign in / sign out / admin gate
   ================================================================= */
async function checkAdminMembership(uid) {
  // Only the user's own /admins/{uid} doc is readable (see firestore.rules).
  // If it does not exist, the user is not an admin and must be signed out.
  const snap = await db.collection("admins").doc(uid).get();
  return snap.exists;
}

function friendlyAuthError(err) {
  switch (err && err.code) {
    case "auth/user-not-found":
    case "auth/wrong-password":
    case "auth/invalid-credential":
      return "Invalid email or password.";
    case "auth/invalid-email":
      return "Please enter a valid email address.";
    case "auth/too-many-requests":
      return "Too many failed attempts. Please wait a moment and try again.";
    case "auth/network-request-failed":
      return "Network error. Check your connection and try again.";
    default:
      return (err && err.message) || "Sign-in failed. Please try again.";
  }
}

$("login-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = $("login-email").value.trim();
  const password = $("login-password").value;
  $("login-error").hidden = true;
  $("login-btn").disabled = true;
  try {
    await auth.signInWithEmailAndPassword(email, password);
    // Admin gate is verified in onAuthStateChanged -> checkAdminMembership.
  } catch (err) {
    $("login-error").textContent = friendlyAuthError(err);
    $("login-error").hidden = false;
  } finally {
    $("login-btn").disabled = false;
  }
});

$("btn-logout").addEventListener("click", async () => {
  await auth.signOut();
});

auth && 0; // (auth is assigned in initFirebase below)

function wireAuthListener() {
  auth.onAuthStateChanged(async (user) => {
    if (!user) {
      showView("view-login");
      return;
    }
    try {
      const isAdmin = await checkAdminMembership(user.uid);
      if (!isAdmin) {
        await auth.signOut();
        $("login-error").textContent =
          "This account is signed in, but it is not registered as an administrator. Ask an existing admin to add /admins/{uid} for your account (see admin/README.md).";
        $("login-error").hidden = false;
        showView("view-login");
        return;
      }
      $("admin-email").textContent = user.email || "";
      showView("view-dashboard");
      loadDashboard();
    } catch (err) {
      console.error("Admin check failed:", err);
      await auth.signOut();
      $("login-error").textContent =
        "Could not verify administrator status (Firestore unreachable). Check the Firebase configuration and try again.";
      $("login-error").hidden = false;
      showView("view-login");
    }
  });
}

/* =================================================================
   Dashboard — tabs, search, list, actions
   ================================================================= */
let allAds = []; // full snapshot for the admin (all statuses)
let activeTab = "published";
let searchTerm = "";

$("btn-new").addEventListener("click", () => openEditor(null));
$("btn-retry").addEventListener("click", loadDashboard);
$("search-input").addEventListener("input", (e) => {
  searchTerm = e.target.value.trim().toLowerCase();
  renderList();
});

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => {
    activeTab = tab.dataset.tab;
    document.querySelectorAll(".tab").forEach((t) => {
      const on = t === tab;
      t.classList.toggle("active", on);
      t.setAttribute("aria-selected", on ? "true" : "false");
    });
    renderList();
  });
});

function adFromDoc(doc) {
  const data = doc.data() || {};
  return { id: doc.id, ...data };
}

/** Tab membership. "expired" = published AND lastDate before today (PKT). */
function adMatchesTab(ad, tab) {
  const expired = ad.status === "published" && ad.lastDate && daysUntilPKT(ad.lastDate) < 0;
  switch (tab) {
    case "published":
      return ad.status === "published" && !expired;
    case "drafts":
      return ad.status === "draft";
    case "archived":
      return ad.status === "archived";
    case "expired":
      return !!expired;
    default:
      return false;
  }
}

async function loadDashboard() {
  $("list-loading").hidden = false;
  $("list-error").hidden = true;
  $("list-empty").hidden = true;
  $("ad-list").innerHTML = "";
  $("dashboard-status").textContent = "";
  try {
    // Admins can list everything; public app clients can only list published
    // (enforced by firestore.rules, not by this query).
    const snap = await db
      .collection("advertisements")
      .orderBy("updatedAt", "desc")
      .limit(500)
      .get();
    allAds = snap.docs.map(adFromDoc);
    updateCounts();
    renderList();
  } catch (err) {
    console.error("loadDashboard failed:", err);
    $("list-error-detail").textContent =
      (err && err.message) || "Unknown error.";
    $("list-error").hidden = false;
  } finally {
    $("list-loading").hidden = true;
  }
}

function updateCounts() {
  const tabs = ["published", "drafts", "archived", "expired"];
  tabs.forEach((t) => {
    $("count-" + t).textContent = allAds.filter((ad) => adMatchesTab(ad, t)).length;
  });
}

function filteredAds() {
  let list = allAds.filter((ad) => adMatchesTab(ad, activeTab));
  if (searchTerm) {
    list = list.filter(
      (ad) =>
        (ad.title || "").toLowerCase().includes(searchTerm) ||
        (ad.organization || "").toLowerCase().includes(searchTerm)
    );
  }
  return list;
}

function renderList() {
  const list = filteredAds();
  $("list-empty").hidden = list.length !== 0;
  $("dashboard-status").textContent =
    list.length === 0 ? "" : `${list.length} advertisement${list.length === 1 ? "" : "s"}`;
  const wrap = $("ad-list");
  wrap.innerHTML = "";
  list.forEach((ad) => wrap.appendChild(adCard(ad)));
}

function adCard(ad) {
  const card = document.createElement("article");
  card.className = "ad-card";

  const dl = deadlineLabel(ad);
  const badgeTone = dl.tone === "expired" ? "badge-expired" : `badge-deadline ${dl.tone === "neutral" ? "" : dl.tone}`;
  const isNew = ad.status === "published" && isNewAd(ad);

  const thumb = ad.posterUrl
    ? `<img class="thumb" src="${esc(ad.posterUrl)}" alt="Poster for ${esc(ad.title)}" loading="lazy" onerror="this.outerHTML='<div class=&quot;thumb-placeholder&quot;>Poster failed to load</div>'" />`
    : `<div class="thumb-placeholder">No poster</div>`;

  card.innerHTML = `
    ${thumb}
    <div class="ad-card-body">
      <div class="preview-badges">
        <span class="badge badge-category">${esc(CATEGORY_LABELS[ad.category] || ad.category || "—")}</span>
        <span class="badge ${badgeTone}">${esc(dl.text)}${ad.lastDate ? ` · ${esc(formatPKTDate(ad.lastDate))}` : ""}</span>
        ${isNew ? `<span class="badge badge-new">NEW</span>` : ""}
        ${ad.isFeatured ? `<span class="badge badge-deadline fine">FEATURED</span>` : ""}
      </div>
      <h4>${esc(ad.title)}</h4>
      <p class="muted small" style="margin:0">${esc(ad.organization || "")}${ad.location ? " · " + esc(ad.location) : ""}</p>
      <div class="ad-card-actions"></div>
    </div>`;

  const actions = card.querySelector(".ad-card-actions");
  const addBtn = (label, cls, handler) => {
    const b = document.createElement("button");
    b.className = `btn ${cls || ""}`.trim();
    b.textContent = label;
    b.addEventListener("click", handler);
    actions.appendChild(b);
  };

  addBtn("Edit", "", () => openEditor(ad.id));

  if (ad.status === "draft") {
    addBtn("Publish", "primary", () => changeStatus(ad, "published"));
  } else if (ad.status === "published") {
    addBtn("Unpublish", "", () => changeStatus(ad, "draft"));
    addBtn("Archive", "ghost", () => changeStatus(ad, "archived"));
  } else if (ad.status === "archived") {
    addBtn("Publish", "primary", () => changeStatus(ad, "published"));
  }
  addBtn("Delete", "danger", () => deleteAd(ad));

  return card;
}

/** Status transitions (publish / unpublish / archive). */
async function changeStatus(ad, newStatus) {
  const verb = { published: "publish", draft: "unpublish to drafts", archived: "archive" }[newStatus] || newStatus;
  const ok = await confirmDialog(
    `${verb[0].toUpperCase() + verb.slice(1)} advertisement?`,
    `"${ad.title}" will be moved to ${newStatus}.`,
    verb[0].toUpperCase() + verb.slice(1)
  );
  if (!ok) return;
  try {
    const ref = db.collection("advertisements").doc(ad.id);
    const patch = { status: newStatus, updatedAt: firebase.firestore.FieldValue.serverTimestamp() };
    if (newStatus === "published" && !ad.publishedAt) {
      patch.publishedAt = firebase.firestore.FieldValue.serverTimestamp();
    }
    await ref.update(patch);
    toast(`Advertisement ${verb}ed.`);
    loadDashboard();
  } catch (err) {
    console.error("changeStatus failed:", err);
    toast(`Could not update status: ${err.message || err}`, "error");
  }
}

/** Permanent deletion. Prefer Archive; deletion is irreversible. */
async function deleteAd(ad) {
  const ok = await confirmDialog(
    "Delete advertisement permanently?",
    `"${ad.title}" will be deleted forever. Consider archiving instead so the record is preserved.`,
    "Delete"
  );
  if (!ok) return;
  try {
    await db.collection("advertisements").doc(ad.id).delete();
    // Best-effort poster cleanup (folder naming: posters/{adId}/{filename}).
    try {
      const folder = storage.ref(`posters/${ad.id}`);
      const items = await folder.listAll();
      await Promise.all(items.items.map((i) => i.delete()));
    } catch (cleanupErr) {
      console.warn("Poster cleanup skipped:", cleanupErr);
    }
    toast("Advertisement deleted.");
    loadDashboard();
  } catch (err) {
    console.error("deleteAd failed:", err);
    toast(`Could not delete: ${err.message || err}`, "error");
  }
}

/* =================================================================
   Editor — create / edit, validation, live preview, poster upload
   ================================================================= */
let editingId = null; // null => new advertisement
let uploadedPosterUrl = ""; // download URL from Storage after successful upload
let posterUploadTask = null;

$("btn-back").addEventListener("click", () => showView("view-dashboard"));
$("btn-cancel").addEventListener("click", () => showView("view-dashboard"));
$("btn-save-draft").addEventListener("click", () => submitForm("draft"));
$("btn-publish").addEventListener("click", () => submitForm("published"));

function openEditor(adId) {
  editingId = adId;
  resetForm();
  $("editor-title").textContent = adId ? "Edit advertisement" : "New advertisement";
  $("editor-id").textContent = adId ? `ID: ${adId}` : "";
  if (adId) {
    const ad = allAds.find((a) => a.id === adId);
    if (ad) fillForm(ad);
    else {
      toast("Advertisement not found in the loaded list.", "error");
      return;
    }
  }
  showView("view-editor");
  updatePreview();
}

function resetForm() {
  $("editor-form").reset();
  uploadedPosterUrl = "";
  posterUploadTask && posterUploadTask.cancel();
  posterUploadTask = null;
  $("poster-preview-wrap").hidden = true;
  $("poster-preview").removeAttribute("src");
  $("upload-progress-wrap").hidden = true;
  $("upload-progress-bar").style.width = "0%";
  $("upload-status").textContent = "";
  $("form-error").hidden = true;
  ["title", "organization", "category", "lastDate", "description", "poster", "sourceUrl", "applicationUrl"].forEach(
    clearFieldError
  );
}

function fillForm(ad) {
  $("f-title").value = ad.title || "";
  $("f-organization").value = ad.organization || "";
  $("f-category").value = CATEGORIES.includes(ad.category) ? ad.category : "jobs";
  $("f-description").value = ad.description || "";
  $("f-lastDate").value = ad.lastDate || "";
  $("f-sourceUrl").value = ad.sourceUrl || "";
  $("f-applicationUrl").value = ad.applicationUrl || "";
  $("f-location").value = ad.location || "";
  $("f-featured").checked = !!ad.isFeatured;
  if (ad.posterUrl) {
    uploadedPosterUrl = ad.posterUrl;
    $("poster-preview").src = ad.posterUrl;
    $("poster-preview-wrap").hidden = false;
    $("upload-status").textContent = "Current poster (upload a new file to replace it).";
  }
}

/* ---------- Field-level validation ---------- */
function setFieldError(name, msg) {
  const el = $("e-" + name);
  if (msg) {
    el.textContent = msg;
    el.hidden = false;
  } else {
    clearFieldError(name);
  }
}
function clearFieldError(name) {
  const el = $("e-" + name);
  el.hidden = true;
  el.textContent = "";
}

function isHttpsUrl(v) {
  if (!v) return true; // optional fields
  try {
    const u = new URL(v);
    return u.protocol === "https:";
  } catch {
    return false;
  }
}

/** Validate the whole form. Returns { ok, values } with cleaned values. */
function validateForm() {
  let ok = true;
  const values = {};

  const title = $("f-title").value.trim();
  if (!title) {
    setFieldError("title", "Headline is required.");
    ok = false;
  } else if (title.length > 200) {
    setFieldError("title", "Headline must be 200 characters or fewer.");
    ok = false;
  } else setFieldError("title");
  values.title = title;

  const organization = $("f-organization").value.trim();
  if (!organization) {
    setFieldError("organization", "Organization / department is required.");
    ok = false;
  } else if (organization.length > 120) {
    setFieldError("organization", "Organization must be 120 characters or fewer.");
    ok = false;
  } else setFieldError("organization");
  values.organization = organization;

  const category = $("f-category").value;
  if (!CATEGORIES.includes(category)) {
    setFieldError("category", "Please choose a valid category.");
    ok = false;
  } else setFieldError("category");
  values.category = category;

  const description = $("f-description").value.trim();
  if (!description) {
    setFieldError("description", "Description is required.");
    ok = false;
  } else setFieldError("description");
  values.description = description;

  const lastDateRaw = $("f-lastDate").value;
  if (lastDateRaw) {
    if (!DATE_RE.test(lastDateRaw) || Number.isNaN(Date.parse(lastDateRaw))) {
      setFieldError("lastDate", "Last date must be a valid YYYY-MM-DD date.");
      ok = false;
    } else setFieldError("lastDate");
    values.lastDate = lastDateRaw;
  } else {
    values.lastDate = null; // not specified -> stored as null/absent
  }

  const sourceUrl = $("f-sourceUrl").value.trim();
  if (sourceUrl && !isHttpsUrl(sourceUrl)) {
    setFieldError("sourceUrl", "Official source URL must start with https://");
    ok = false;
  } else setFieldError("sourceUrl");
  values.sourceUrl = sourceUrl || null;

  const applicationUrl = $("f-applicationUrl").value.trim();
  if (applicationUrl && !isHttpsUrl(applicationUrl)) {
    setFieldError("applicationUrl", "Application URL must start with https://");
    ok = false;
  } else setFieldError("applicationUrl");
  values.applicationUrl = applicationUrl || null;

  values.location = $("f-location").value.trim() || null;
  values.isFeatured = $("f-featured").checked;

  return { ok, values };
}

/* ---------- Poster upload ---------- */
$("f-poster").addEventListener("change", (e) => {
  const file = e.target.files && e.target.files[0];
  setFieldError("poster");
  if (!file) return;

  // Local validation (mirrors storage.rules server-side checks).
  if (!POSTER_MIME_TYPES.includes(file.type)) {
    setFieldError("poster", "Only JPG, PNG or WebP images are allowed.");
    e.target.value = "";
    return;
  }
  if (file.size > POSTER_MAX_BYTES) {
    setFieldError("poster", "Image must be 5 MB or smaller.");
    e.target.value = "";
    return;
  }

  // Preview locally.
  const reader = new FileReader();
  reader.onload = () => {
    $("poster-preview").src = reader.result;
    $("poster-preview-wrap").hidden = false;
  };
  reader.readAsDataURL(file);

  // Upload to Storage at posters/{adId}/{filename}.
  // For a new ad we reserve a doc ID up-front so the path is stable.
  const adId = editingId || db.collection("advertisements").doc().id;
  if (!editingId) editingId = adId; // pin the reserved ID for this session
  $("editor-id").textContent = `ID: ${adId} (reserved)`;

  const safeName = `${Date.now()}_${file.name.replace(/[^a-zA-Z0-9._-]/g, "_")}`;
  const ref = storage.ref(`posters/${adId}/${safeName}`);

  posterUploadTask && posterUploadTask.cancel();
  const task = storage.ref(`posters/${adId}/${safeName}`).put(file, {
    contentType: file.type,
  });
  posterUploadTask = task;

  // If the upload stalls (e.g. Firebase Storage is not enabled on the
  // project — it needs the Blaze plan), don't block publishing forever:
  // cancel it and explain clearly.
  let lastProgressAt = Date.now();
  const stallTimer = setInterval(() => {
    if (posterUploadTask !== task) {
      clearInterval(stallTimer);
      return;
    }
    if (Date.now() - lastProgressAt > 45000) {
      clearInterval(stallTimer);
      task.cancel();
      posterUploadTask = null;
      $("upload-status").textContent = "";
      $("upload-progress-wrap").hidden = true;
      setFieldError(
        "poster",
        "Poster upload timed out — Firebase Storage is not enabled on this " +
          "project (it needs the Blaze plan upgrade). Remove the poster or " +
          "publish without one."
      );
    }
  }, 5000);

  $("upload-progress-wrap").hidden = false;
  $("upload-status").textContent = "Uploading...";
  task.on(
    "state_changed",
    (snap) => {
      lastProgressAt = Date.now();
      const pct = Math.round((snap.bytesTransferred / snap.totalBytes) * 100);
      $("upload-progress-bar").style.width = pct + "%";
      $("upload-status").textContent = `Uploading... ${pct}%`;
    },
    (err) => {
      clearInterval(stallTimer);
      console.error("Poster upload failed:", err);
      const code = (err && err.code) || "";
      const storageDown =
        code.indexOf("bucket-not-found") !== -1 ||
        code.indexOf("project-not-found") !== -1 ||
        code.indexOf("unknown") !== -1;
      setFieldError(
        "poster",
        storageDown
          ? "Upload failed: Firebase Storage is not enabled on this project " +
              "(it needs the Blaze plan upgrade). Remove the poster or publish without one."
          : `Upload failed: ${err.message || err}`
      );
      $("upload-status").textContent = "";
      $("upload-progress-wrap").hidden = true;
      posterUploadTask = null;
    },
    async () => {
      clearInterval(stallTimer);
      uploadedPosterUrl = await task.snapshot.ref.getDownloadURL();
      $("upload-status").textContent = "Upload complete.";
      $("upload-progress-wrap").hidden = true;
      posterUploadTask = null;
      toast("Poster uploaded.");
      updatePreview();
    }
  );
  void ref; // ref kept for clarity of the Storage path convention
});

/* ---------- Remove poster ---------- */
$("btn-remove-poster").addEventListener("click", () => {
  posterUploadTask && posterUploadTask.cancel();
  posterUploadTask = null;
  uploadedPosterUrl = "";
  $("f-poster").value = "";
  $("poster-preview").removeAttribute("src");
  $("poster-preview-wrap").hidden = true;
  $("upload-progress-wrap").hidden = true;
  $("upload-progress-bar").style.width = "0%";
  $("upload-status").textContent = "";
  setFieldError("poster");
  updatePreview();
});

/* ---------- Live preview ---------- */
["f-title", "f-organization", "f-category", "f-description", "f-lastDate", "f-location", "f-featured"].forEach((id) => {
  $(id).addEventListener("input", updatePreview);
  $(id).addEventListener("change", updatePreview);
});

function updatePreview() {
  const title = $("f-title").value.trim() || "Your headline will appear here";
  const org = $("f-organization").value.trim() || "Organization";
  const category = $("f-category").value;
  const lastDate = $("f-lastDate").value || null;
  const location = $("f-location").value.trim();

  $("preview-title").textContent = title;
  $("preview-org").textContent = org;
  $("preview-category").textContent = CATEGORY_LABELS[category] || category;
  $("preview-location").textContent = location;
  $("preview-location").style.display = location ? "" : "none";

  const dl = deadlineLabel({ lastDate });
  const badge = $("preview-deadline");
  badge.textContent = dl.text + (lastDate ? ` · ${formatPKTDate(lastDate)}` : "");
  badge.className = `badge badge-deadline${dl.tone === "expired" ? " badge-expired" : dl.tone === "neutral" ? "" : " " + dl.tone}`;

  $("preview-new").hidden = false; // a fresh/edited ad would carry the NEW badge

  const img = $("poster-preview").src;
  const posterBox = $("preview-poster");
  if ($("poster-preview-wrap").hidden || !img) {
    posterBox.innerHTML = '<span class="preview-noimage">No poster</span>';
  } else {
    posterBox.innerHTML = "";
    const im = document.createElement("img");
    im.src = uploadedPosterUrl || img;
    im.alt = "Poster preview";
    posterBox.appendChild(im);
  }
}

/* ---------- Submit (Save as draft / Publish) ---------- */
async function submitForm(targetStatus) {
  if (posterUploadTask) {
    $("form-error").textContent = "Please wait for the poster upload to finish.";
    $("form-error").hidden = false;
    return;
  }
  const { ok, values } = validateForm();
  if (!ok) {
    $("form-error").textContent = "Please fix the highlighted fields and try again.";
    $("form-error").hidden = false;
    return;
  }
  $("form-error").hidden = true;

  $("btn-save-draft").disabled = true;
  $("btn-publish").disabled = true;
  try {
    const now = firebase.firestore.FieldValue.serverTimestamp();
    const user = auth.currentUser;
    const docRef = editingId
      ? db.collection("advertisements").doc(editingId)
      : db.collection("advertisements").doc();

    const data = {
      title: values.title,
      organization: values.organization,
      category: values.category,
      description: values.description,
      location: values.location,
      posterUrl: uploadedPosterUrl || null,
      lastDate: values.lastDate,
      status: targetStatus,
      isFeatured: values.isFeatured,
      updatedAt: now,
    };

    // Optional URL fields: the security rules reject explicit nulls
    // ("Missing or insufficient permissions"), so omit them when creating
    // and delete them when cleared on update.
    const del = firebase.firestore.FieldValue.delete();

    if (editingId) {
      const snap = await docRef.get();
      data.sourceUrl = values.sourceUrl || del;
      data.applicationUrl = values.applicationUrl || del;
      if (snap.exists) {
        await docRef.update(data); // never fabricate createdAt/createdBy on edit
      } else {
        // Reserved ID from poster upload, but doc never saved: create now.
        data.createdAt = now;
        data.createdBy = user.uid;
        if (targetStatus === "published") data.publishedAt = now;
        await docRef.set(data);
      }
    } else {
      if (values.sourceUrl) data.sourceUrl = values.sourceUrl;
      if (values.applicationUrl) data.applicationUrl = values.applicationUrl;
      data.createdAt = now;
      data.createdBy = user.uid;
      if (targetStatus === "published") data.publishedAt = now;
      await docRef.set(data);
      editingId = docRef.id;
    }

    toast(
      targetStatus === "published"
        ? "Advertisement published. It is now visible in the app."
        : "Draft saved."
    );
    showView("view-dashboard");
    loadDashboard();
  } catch (err) {
    console.error("submitForm failed:", err);
    $("form-error").textContent = `Save failed: ${err.message || err}`;
    $("form-error").hidden = false;
  } finally {
    $("btn-save-draft").disabled = false;
    $("btn-publish").disabled = false;
  }
}

/* =================================================================
   Teaching review — Private Teaching Jobs moderation queues
   -----------------------------------------------------------------
   Review queues for the teachingOrganizations, teacherProfiles and
   teachingVacancies collections. Same security model as the
   advertisements dashboard: this UI enforces nothing — Firestore
   rules decide which reads/writes succeed, and permission errors are
   surfaced as toasts instead of crashing the panel.
   ================================================================= */

const TEACH_QUEUES = ["organizations", "teachers", "vacancies"];
const TEACH_COLLECTIONS = {
  organizations: "teachingOrganizations",
  teachers: "teacherProfiles",
  vacancies: "teachingVacancies",
};
const TEACH_STATUS_FILTERS = {
  organizations: ["pending", "approved", "suspended", "rejected"],
  teachers: ["pending", "approved", "suspended", "rejected"],
  vacancies: ["pending", "approved", "rejected", "expired"],
};
const TEACH_SEARCH_PLACEHOLDERS = {
  organizations: "Search organizations...",
  teachers: "Search teachers...",
  vacancies: "Search vacancies...",
};
const TEACH_STATUS_LABELS = {
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
  suspended: "Suspended",
  expired: "Expired",
};

let teachQueue = "organizations";
let teachFilter = "pending";
let teachSearch = "";
let teachData = { organizations: [], teachers: [], vacancies: [] };
let teachErrors = {}; // queue -> error message when that collection read failed
let orgNameCache = {}; // teachingOrganizations doc id -> institutionName

/* ---------- small formatting helpers ---------- */
const MONTHS_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function fmtTs(ts) {
  if (!ts) return "—";
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  if (Object.prototype.toString.call(d) !== "[object Date]" || isNaN(d.getTime())) return "—";
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  return `${d.getDate()} ${MONTHS_SHORT[d.getMonth()]} ${d.getFullYear()}, ${hh}:${mm}`;
}

function arrJoin(v) {
  if (Array.isArray(v)) return v.filter(Boolean).join(", ") || "—";
  return v ? String(v) : "—";
}

function trunc(s, n) {
  s = String(s || "");
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

function salaryLabel(v) {
  const hasMin = v.salaryMin != null && v.salaryMin !== "";
  const hasMax = v.salaryMax != null && v.salaryMax !== "";
  if (hasMin && hasMax) return `Rs ${v.salaryMin} – ${v.salaryMax}`;
  if (hasMin) return `Rs ${v.salaryMin}+`;
  if (hasMax) return `Up to Rs ${v.salaryMax}`;
  return "Not specified";
}

/** Normalize applicationDeadline (YYYY-MM-DD string or Timestamp/Date)
    to a PKT YYYY-MM-DD string, then reuse the ad deadline logic. */
function teachDeadlineInfo(v) {
  const dl = v.applicationDeadline;
  let str = null;
  if (typeof dl === "string" && DATE_RE.test(dl)) {
    str = dl;
  } else if (dl) {
    const d = dl.toDate ? dl.toDate() : new Date(dl);
    if (!isNaN(d.getTime())) {
      const pkt = new Date(d.getTime() + 5 * 60 * 60 * 1000);
      str =
        `${pkt.getUTCFullYear()}-${String(pkt.getUTCMonth() + 1).padStart(2, "0")}-` +
        String(pkt.getUTCDate()).padStart(2, "0");
    }
  }
  return { str, label: deadlineLabel({ lastDate: str }) };
}

/** Value suitable for an <input type="date"> from an applicationDeadline. */
function dateInputValue(dl) {
  if (typeof dl === "string" && DATE_RE.test(dl)) return dl;
  if (dl) {
    const d = dl.toDate ? dl.toDate() : new Date(dl);
    if (!isNaN(d.getTime())) {
      const pkt = new Date(d.getTime() + 5 * 60 * 60 * 1000);
      return (
        `${pkt.getUTCFullYear()}-${String(pkt.getUTCMonth() + 1).padStart(2, "0")}-` +
        String(pkt.getUTCDate()).padStart(2, "0")
      );
    }
  }
  return "";
}

function teachStatusBadge(status) {
  const s = status || "pending";
  const cls =
    {
      pending: "badge-pending",
      approved: "badge-approved",
      rejected: "badge-rejected",
      suspended: "badge-suspended",
      expired: "badge-expired",
    }[s] || "badge-deadline";
  return `<span class="badge ${cls}">${esc(TEACH_STATUS_LABELS[s] || s)}</span>`;
}

function teachDisplayName(queue, doc) {
  if (queue === "organizations") return doc.institutionName || "Unnamed institution";
  if (queue === "teachers") return doc.fullName || "Unnamed teacher";
  return doc.jobTitle || "Untitled vacancy";
}

/* ---------- dialog with input fields (reject reasons, quick edits) ----------
   Reuses the existing confirm overlay. Resolves to { id: value } when
   confirmed and valid, or null when cancelled. Validation failures keep
   the dialog open with inline errors. */
function promptFields(title, message, fields, okLabel = "Save") {
  $("confirm-title").textContent = title;
  $("confirm-message").textContent = message || "";
  $("confirm-ok").textContent = okLabel;
  const initial = {};
  fields.forEach((f) => {
    initial[f.id] = f.value || "";
  });

  function renderForm(values, errors) {
    const custom = $("confirm-custom");
    custom.innerHTML = "";
    custom.hidden = false;
    const inputs = {};
    fields.forEach((f) => {
      const label = document.createElement("label");
      label.className = "field";
      const span = document.createElement("span");
      span.textContent = f.label + (f.required ? " *" : "");
      label.appendChild(span);
      let input;
      if (f.type === "textarea") {
        input = document.createElement("textarea");
        input.rows = 4;
      } else {
        input = document.createElement("input");
        input.type = f.type === "date" ? "date" : "text";
      }
      input.value = values[f.id] || "";
      if (f.placeholder) input.placeholder = f.placeholder;
      label.appendChild(input);
      const err = document.createElement("small");
      err.className = "field-error";
      if (errors[f.id]) {
        err.textContent = errors[f.id];
      } else {
        err.hidden = true;
      }
      label.appendChild(err);
      custom.appendChild(label);
      inputs[f.id] = input;
    });
    return inputs;
  }

  let inputs = renderForm(initial, {});
  $("confirm-overlay").hidden = false;

  return new Promise((resolve) => {
    const attempt = (ok) => {
      if (!ok) {
        resolve(null);
        return;
      }
      const values = {};
      const errors = {};
      fields.forEach((f) => {
        const v = inputs[f.id].value.trim();
        values[f.id] = v;
        if (f.required && !v) {
          errors[f.id] = "This field is required.";
        } else if (v && f.type === "date" && !DATE_RE.test(v)) {
          errors[f.id] = "Enter a valid date (YYYY-MM-DD).";
        }
      });
      if (Object.keys(errors).length > 0) {
        // The shared dialog handler already hid the overlay, cleared the
        // form and nulled confirmResolve; rebuild the form with the entered
        // values plus errors, re-show it, and re-arm (deferred so the
        // re-arm runs after the handler's synchronous `confirmResolve = null`).
        inputs = renderForm(values, errors);
        $("confirm-overlay").hidden = false;
        setTimeout(() => {
          confirmResolve = attempt;
        }, 0);
        return;
      }
      resolve(values);
    };
    confirmResolve = attempt;
  });
}

/* ---------- navigation wiring ---------- */
$("btn-teaching").addEventListener("click", () => {
  showView("view-teaching");
  loadTeaching();
});
$("btn-teaching-back").addEventListener("click", () => showView("view-dashboard"));
$("btn-teaching-retry").addEventListener("click", loadTeaching);
$("teaching-search-input").addEventListener("input", (e) => {
  teachSearch = e.target.value.trim().toLowerCase();
  renderTeaching();
});

document.querySelectorAll(".ttab").forEach((tab) => {
  tab.addEventListener("click", () => {
    teachQueue = tab.dataset.ttab;
    teachFilter = "pending";
    teachSearch = "";
    $("teaching-search-input").value = "";
    document.querySelectorAll(".ttab").forEach((t) => {
      const on = t === tab;
      t.classList.toggle("active", on);
      t.setAttribute("aria-selected", on ? "true" : "false");
    });
    renderTeaching();
  });
});

/* ---------- loading ---------- */
async function loadTeaching() {
  $("teaching-list-loading").hidden = false;
  $("teaching-list-error").hidden = true;
  $("teaching-list-empty").hidden = true;
  $("teaching-list").innerHTML = "";
  $("teaching-status").textContent = "";
  teachErrors = {};
  try {
    const results = await Promise.all(
      TEACH_QUEUES.map((q) =>
        db
          .collection(TEACH_COLLECTIONS[q])
          .orderBy("updatedAt", "desc")
          .limit(500)
          .get()
          .then((snap) => ({
            queue: q,
            docs: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
          }))
          .catch((err) => ({ queue: q, error: err }))
      )
    );
    results.forEach((r) => {
      if (r.error) {
        teachData[r.queue] = [];
        teachErrors[r.queue] = (r.error && r.error.message) || "Unknown error.";
      } else {
        teachData[r.queue] = r.docs;
      }
    });
    await ensureOrgNames();
  } catch (err) {
    console.error("loadTeaching failed:", err);
  } finally {
    $("teaching-list-loading").hidden = true;
    renderTeaching();
  }
}

/** Resolve organizationId -> institutionName for vacancy cards (cached). */
async function ensureOrgNames() {
  const ids = new Set();
  teachData.vacancies.forEach((v) => {
    if (v.organizationId && !orgNameCache[v.organizationId]) ids.add(v.organizationId);
  });
  await Promise.all(
    [...ids].map(async (id) => {
      try {
        const snap = await db.collection(TEACH_COLLECTIONS.organizations).doc(id).get();
        orgNameCache[id] = snap.exists
          ? snap.data().institutionName || "Unnamed institution"
          : "Unknown institution";
      } catch (e) {
        orgNameCache[id] = "Unknown institution";
      }
    })
  );
}

/* ---------- filtering / rendering ---------- */
function teachMatchesFilter(queue, doc, filter) {
  const status = doc.approvalStatus || "pending";
  if (queue === "vacancies" && filter === "expired") {
    if (status === "expired") return true;
    if (status !== "approved") return false;
    return teachDeadlineInfo(doc).label.tone === "expired";
  }
  if (queue === "vacancies" && filter === "approved") {
    // Mirror the advertisements dashboard: past-deadline items live under "expired".
    return status === "approved" && teachDeadlineInfo(doc).label.tone !== "expired";
  }
  return status === filter;
}

function teachSearchText(queue, doc) {
  const parts = [];
  if (queue === "organizations") {
    parts.push(doc.institutionName, doc.contactPerson, doc.email, doc.district, doc.city, doc.institutionType, doc.id);
  } else if (queue === "teachers") {
    parts.push(doc.fullName, doc.email, doc.district, doc.qualification, arrJoin(doc.subjects), doc.id);
  } else {
    parts.push(doc.jobTitle, doc.district, doc.city, doc.qualification, arrJoin(doc.subjects), doc.id);
  }
  return parts.filter(Boolean).join(" ").toLowerCase();
}

function filteredTeaching() {
  let list = teachData[teachQueue].filter((d) => teachMatchesFilter(teachQueue, d, teachFilter));
  if (teachSearch) {
    list = list.filter((d) => teachSearchText(teachQueue, d).includes(teachSearch));
  }
  return list;
}

function renderTeaching() {
  // Queue tab counts show pending items (the actual review workload).
  TEACH_QUEUES.forEach((q) => {
    const n = teachData[q].filter((d) => (d.approvalStatus || "pending") === "pending").length;
    $("count-t-" + q).textContent = n;
  });

  // Status filter tabs for the active queue.
  const nav = $("teaching-filters");
  nav.innerHTML = "";
  TEACH_STATUS_FILTERS[teachQueue].forEach((f) => {
    const n = teachData[teachQueue].filter((d) => teachMatchesFilter(teachQueue, d, f)).length;
    const b = document.createElement("button");
    b.className = "tftab" + (f === teachFilter ? " active" : "");
    b.setAttribute("role", "tab");
    b.setAttribute("aria-selected", f === teachFilter ? "true" : "false");
    b.innerHTML = `${esc(TEACH_STATUS_LABELS[f])} <span class="count">${n}</span>`;
    b.addEventListener("click", () => {
      teachFilter = f;
      renderTeaching();
    });
    nav.appendChild(b);
  });

  $("teaching-search-input").placeholder = TEACH_SEARCH_PLACEHOLDERS[teachQueue];

  const err = teachErrors[teachQueue];
  const list = err ? [] : filteredTeaching();
  $("teaching-list-error").hidden = !err;
  if (err) $("teaching-list-error-detail").textContent = err;
  $("teaching-list-empty").hidden = err || list.length !== 0;
  $("teaching-status").textContent =
    err || list.length === 0 ? "" : `${list.length} record${list.length === 1 ? "" : "s"}`;

  const wrap = $("teaching-list");
  wrap.innerHTML = "";
  list.forEach((d) => wrap.appendChild(teachCard(d)));
}

/* ---------- card builders ---------- */
function teachAddBtn(actionsEl, label, cls, handler) {
  const b = document.createElement("button");
  b.className = `btn ${cls || ""}`.trim();
  b.textContent = label;
  b.addEventListener("click", handler);
  actionsEl.appendChild(b);
}

/** Shared card shell: status badges, title, subtitle, key/value rows. */
function teachCardShell(statusHtml, title, subtitle, kvRows, extraHtml) {
  const card = document.createElement("article");
  card.className = "ad-card";
  const kv = (kvRows || [])
    .map(([k, v]) => `<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`)
    .join("");
  card.innerHTML = `
    <div class="ad-card-body">
      <div class="preview-badges">${statusHtml}</div>
      <h4>${esc(title)}</h4>
      ${subtitle ? `<p class="muted small" style="margin:0">${esc(subtitle)}</p>` : ""}
      ${kv ? `<dl class="kv">${kv}</dl>` : ""}
      ${extraHtml || ""}
      <div class="ad-card-actions"></div>
    </div>`;
  return card;
}

function teachCard(doc) {
  if (teachQueue === "organizations") return orgCard(doc);
  if (teachQueue === "teachers") return teacherCard(doc);
  return vacancyCard(doc);
}

function orgCard(org) {
  const loc = [org.district, org.city].filter(Boolean).join(", ");
  const rows = [
    ["Contact person", org.contactPerson || "—"],
    ["Email", org.email || "—"],
    ["Phone", org.contactNumber || "—"],
    ["Address", org.address || "—"],
    ["Submitted", fmtTs(org.createdAt)],
  ];
  if (org.rejectionReason) rows.push(["Rejection reason", org.rejectionReason]);
  const card = teachCardShell(
    teachStatusBadge(org.approvalStatus),
    org.institutionName || "Unnamed institution",
    [org.institutionType, loc].filter(Boolean).join(" · "),
    rows,
    ""
  );
  const actions = card.querySelector(".ad-card-actions");
  const st = org.approvalStatus || "pending";
  if (st === "pending" || st === "rejected") {
    teachAddBtn(actions, "Approve", "primary", () => teachApprove("organizations", org));
  }
  if (st === "pending") {
    teachAddBtn(actions, "Reject", "", () => teachReject("organizations", org));
  }
  if (st === "approved") {
    teachAddBtn(actions, "Suspend", "danger", () => teachSuspend("organizations", org));
  }
  if (st === "suspended") {
    teachAddBtn(actions, "Reactivate", "primary", () => teachReactivate("organizations", org));
  }
  teachAddBtn(actions, "Edit details", "", () => teachEditOrg(org));
  return card;
}

/* ---------- edit institution details (admin correction) ---------- */
async function teachEditOrg(org) {
  const result = await promptFields(
    "Edit institution details",
    `Correcting details for "${org.institutionName || org.id}". This only changes the organization's own record.`,
    [
      { id: "institutionName", label: "Institution name", value: org.institutionName, required: true },
      { id: "contactPerson", label: "Contact person", value: org.contactPerson },
      { id: "contactNumber", label: "Phone number", value: org.contactNumber },
      { id: "district", label: "District", value: org.district },
      { id: "city", label: "City", value: org.city },
      { id: "address", label: "Address", value: org.address, type: "textarea" },
    ],
    "Save changes"
  );
  if (!result) return;
  if (!result.institutionName.trim()) {
    toast("Institution name is required.", "error");
    return;
  }
  try {
    const ref = db.collection(TEACH_COLLECTIONS.organizations).doc(org.id);
    await ref.update({
      institutionName: result.institutionName.trim(),
      contactPerson: result.contactPerson.trim(),
      contactNumber: result.contactNumber.trim(),
      district: result.district.trim(),
      city: result.city.trim(),
      address: result.address.trim(),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    });
    toast("Institution details updated.", "success");
    await loadTeaching();
  } catch (e) {
    console.error("Edit institution failed:", e);
    toast("Could not save changes: " + (e.message || e), "error");
  }
}

function teacherCard(t) {
  const exp =
    t.experienceYears == null || t.experienceYears === ""
      ? "—"
      : `${t.experienceYears} yr${Number(t.experienceYears) === 1 ? "" : "s"}`;
  const rows = [
    ["Subjects", arrJoin(t.subjects)],
    ["Experience", exp],
    ["Preferred type", t.preferredEmploymentType || "—"],
    ["Email", t.email || "—"],
    // Never render cvStoragePath as a clickable public link: it is a
    // private Storage path and must stay that way.
    ["CV", t.cvStoragePath ? "Attached (private — not publicly linked)" : "No CV attached"],
    ["Public profile", t.profileVisibility || "—"],
    ["Submitted", fmtTs(t.createdAt)],
  ];
  if (t.rejectionReason) rows.push(["Rejection reason", t.rejectionReason]);
  const card = teachCardShell(
    teachStatusBadge(t.approvalStatus),
    t.fullName || "Unnamed teacher",
    [t.qualification, t.district].filter(Boolean).join(" · "),
    rows,
    t.professionalSummary
      ? `<p class="small muted" style="margin:0.5rem 0 0">${esc(trunc(t.professionalSummary, 220))}</p>`
      : ""
  );
  const actions = card.querySelector(".ad-card-actions");
  const st = t.approvalStatus || "pending";
  if (st === "pending" || st === "rejected") {
    teachAddBtn(actions, "Approve", "primary", () => teachApprove("teachers", t));
  }
  if (st === "pending") {
    teachAddBtn(actions, "Reject", "", () => teachReject("teachers", t));
  }
  if (st === "approved") {
    teachAddBtn(actions, "Suspend", "danger", () => teachSuspend("teachers", t));
  }
  if (st === "suspended") {
    teachAddBtn(actions, "Reactivate", "primary", () => teachReactivate("teachers", t));
  }
  return card;
}

function vacancyCard(v) {
  const info = teachDeadlineInfo(v);
  const dl = info.label;
  const dlTone = dl.tone === "expired" ? "badge-expired" : `badge-deadline${dl.tone === "neutral" ? "" : " " + dl.tone}`;
  const orgName = v.organizationId
    ? orgNameCache[v.organizationId] || "…"
    : v.institutionName || "—";
  const rows = [
    ["Subjects", arrJoin(v.subjects)],
    ["Grades", arrJoin(v.gradeLevels)],
    ["Qualification", v.qualification || "—"],
    ["Experience", v.experienceRequired || "—"],
    ["Positions", v.positionsCount != null && v.positionsCount !== "" ? String(v.positionsCount) : "—"],
    ["Salary", salaryLabel(v)],
    ["Employment type", v.employmentType || "—"],
    ["Gender eligibility", v.genderEligibility || "—"],
    ["Apply via", v.applicationMethod || "—"],
    ["Application URL", v.applicationUrl ? trunc(v.applicationUrl, 60) : "—"],
    ["Contact", v.contactInstructions ? trunc(v.contactInstructions, 90) : "—"],
    ["Submitted", fmtTs(v.createdAt)],
    ["Published", fmtTs(v.publishedAt)],
  ];
  if (v.rejectionReason) rows.push(["Rejection reason", v.rejectionReason]);
  const card = teachCardShell(
    `${teachStatusBadge(v.approvalStatus)}<span class="badge ${dlTone}">${esc(dl.text)}${
      info.str ? ` · ${esc(formatPKTDate(info.str))}` : ""
    }</span>`,
    v.jobTitle || "Untitled vacancy",
    [orgName, [v.district, v.city].filter(Boolean).join(", ")].filter(Boolean).join(" · "),
    rows,
    v.description
      ? `<p class="small muted" style="margin:0.5rem 0 0">${esc(trunc(v.description, 220))}</p>`
      : ""
  );
  const actions = card.querySelector(".ad-card-actions");
  const st = v.approvalStatus || "pending";
  if (st === "pending" || st === "rejected") {
    teachAddBtn(actions, "Approve & publish", "primary", () => vacancyApprovePublish(v));
  }
  if (st === "pending" || st === "rejected") {
    teachAddBtn(actions, "Reject", "", () => vacancyReject(v));
  }
  if (st === "approved") {
    teachAddBtn(actions, "Unpublish", "", () => vacancyUnpublish(v));
    teachAddBtn(actions, "Expire", "ghost", () => vacancyExpire(v));
  }
  teachAddBtn(actions, "Edit", "", () => vacancyEdit(v));
  return card;
}

/* ---------- review actions ---------- */
async function teachUpdate(queue, doc, patch, successMsg) {
  try {
    await db
      .collection(TEACH_COLLECTIONS[queue])
      .doc(doc.id)
      .update({
        ...patch,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      });
    toast(successMsg);
    loadTeaching();
  } catch (err) {
    console.error("teachUpdate failed:", err);
    toast(`Could not update: ${err.message || err}`, "error");
  }
}

async function teachApprove(queue, doc) {
  const kind = queue === "vacancies" ? "vacancy" : queue.slice(0, -1);
  const ok = await confirmDialog(
    `Approve this ${kind}?`,
    `"${teachDisplayName(queue, doc)}" will be marked as approved.`,
    "Approve"
  );
  if (!ok) return;
  teachUpdate(queue, doc, { approvalStatus: "approved" }, "Approved.");
}

async function teachReject(queue, doc) {
  const kind = queue === "vacancies" ? "vacancy" : queue.slice(0, -1);
  const vals = await promptFields(
    `Reject this ${kind}?`,
    `"${teachDisplayName(queue, doc)}" will be marked as rejected. A reason is optional and is stored with the record.`,
    [
      {
        id: "reason",
        label: "Rejection reason (optional)",
        type: "textarea",
        placeholder: "e.g. Institution documents could not be verified.",
      },
    ],
    "Reject"
  );
  if (!vals) return;
  const patch = { approvalStatus: "rejected" };
  if (vals.reason) patch.rejectionReason = vals.reason;
  teachUpdate(queue, doc, patch, "Rejected.");
}

async function teachSuspend(queue, doc) {
  const kind = queue.slice(0, -1);
  const ok = await confirmDialog(
    `Suspend this ${kind}?`,
    `"${teachDisplayName(queue, doc)}" will be suspended and hidden from public listings.`,
    "Suspend"
  );
  if (!ok) return;
  teachUpdate(queue, doc, { approvalStatus: "suspended" }, "Suspended.");
}

async function teachReactivate(queue, doc) {
  const kind = queue.slice(0, -1);
  const ok = await confirmDialog(
    `Reactivate this ${kind}?`,
    `"${teachDisplayName(queue, doc)}" will be approved again.`,
    "Reactivate"
  );
  if (!ok) return;
  teachUpdate(queue, doc, { approvalStatus: "approved" }, "Reactivated.");
}

async function vacancyApprovePublish(doc) {
  const ok = await confirmDialog(
    "Approve and publish this vacancy?",
    `"${teachDisplayName("vacancies", doc)}" will become visible in the app.`,
    "Approve & publish"
  );
  if (!ok) return;
  teachUpdate(
    "vacancies",
    doc,
    {
      approvalStatus: "approved",
      publishedAt: firebase.firestore.FieldValue.serverTimestamp(),
    },
    "Vacancy approved and published."
  );
}

async function vacancyReject(doc) {
  return teachReject("vacancies", doc);
}

async function vacancyUnpublish(doc) {
  const ok = await confirmDialog(
    "Unpublish this vacancy?",
    `"${teachDisplayName("vacancies", doc)}" will return to pending and disappear from the app.`,
    "Unpublish"
  );
  if (!ok) return;
  teachUpdate(
    "vacancies",
    doc,
    {
      approvalStatus: "pending",
      publishedAt: firebase.firestore.FieldValue.delete(),
    },
    "Vacancy unpublished (back to pending)."
  );
}

async function vacancyExpire(doc) {
  const ok = await confirmDialog(
    "Mark this vacancy as expired?",
    `"${teachDisplayName("vacancies", doc)}" will be treated as expired and hidden from the active feed.`,
    "Expire"
  );
  if (!ok) return;
  teachUpdate("vacancies", doc, { approvalStatus: "expired" }, "Vacancy marked as expired.");
}

/** Minimal correction editor: title / description / deadline only. */
async function vacancyEdit(doc) {
  const vals = await promptFields(
    "Correct vacancy",
    "Fix the title, description or deadline. All other fields stay unchanged.",
    [
      { id: "jobTitle", label: "Job title", type: "text", value: doc.jobTitle || "", required: true },
      { id: "description", label: "Description", type: "textarea", value: doc.description || "", required: true },
      {
        id: "applicationDeadline",
        label: "Application deadline (optional)",
        type: "date",
        value: dateInputValue(doc.applicationDeadline),
      },
    ],
    "Save changes"
  );
  if (!vals) return;
  const patch = { jobTitle: vals.jobTitle, description: vals.description };
  patch.applicationDeadline = vals.applicationDeadline || firebase.firestore.FieldValue.delete();
  teachUpdate("vacancies", doc, patch, "Vacancy updated.");
}

/* =================================================================
   Boot
   ================================================================= */
(function boot() {
  if (typeof firebase === "undefined") {
    document.body.innerHTML =
      '<div class="login-card" style="margin:4rem auto;max-width:560px;padding:2rem">' +
      "<h2>Failed to load Firebase SDKs</h2>" +
      "<p>The Firebase CDN scripts could not be loaded. Check your internet connection and reload.</p></div>";
    return;
  }
  if (configLooksPlaceholder(FIREBASE_CONFIG)) {
    // Still boot, but warn loudly — nothing will work until configured.
    console.warn(
      "[Afzal Admin] FIREBASE_CONFIG still contains REPLACE_WITH_* placeholders. " +
        "Paste your Firebase web app config at the top of app.js (see admin/README.md)."
    );
  }
  try {
    initFirebase();
  } catch (err) {
    console.error("Firebase init failed:", err);
    toast(`Firebase initialization failed: ${err.message || err}`, "error");
    return;
  }
  wireAuthListener();
  showView("view-login");
})();
