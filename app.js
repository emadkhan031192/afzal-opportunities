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
  apiKey: "REPLACE_WITH_YOUR_API_KEY",
  authDomain: "REPLACE_WITH_YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "REPLACE_WITH_YOUR_PROJECT_ID",
  storageBucket: "REPLACE_WITH_YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "REPLACE_WITH_YOUR_SENDER_ID",
  appId: "REPLACE_WITH_YOUR_APP_ID",
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
  confirmResolve && confirmResolve(false);
  confirmResolve = null;
});
$("confirm-ok").addEventListener("click", () => {
  $("confirm-overlay").hidden = true;
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
const VIEWS = ["view-login", "view-dashboard", "view-editor"];
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

  $("upload-progress-wrap").hidden = false;
  $("upload-status").textContent = "Uploading...";
  task.on(
    "state_changed",
    (snap) => {
      const pct = Math.round((snap.bytesTransferred / snap.totalBytes) * 100);
      $("upload-progress-bar").style.width = pct + "%";
      $("upload-status").textContent = `Uploading... ${pct}%`;
    },
    (err) => {
      console.error("Poster upload failed:", err);
      setFieldError("poster", `Upload failed: ${err.message || err}`);
      $("upload-status").textContent = "";
      $("upload-progress-wrap").hidden = true;
      posterUploadTask = null;
    },
    async () => {
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
      sourceUrl: values.sourceUrl,
      applicationUrl: values.applicationUrl,
      lastDate: values.lastDate,
      status: targetStatus,
      isFeatured: values.isFeatured,
      updatedAt: now,
    };

    if (editingId) {
      const snap = await docRef.get();
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
