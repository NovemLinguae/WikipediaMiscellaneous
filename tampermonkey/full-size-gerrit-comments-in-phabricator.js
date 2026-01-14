// ==UserScript==
// @name         Phabricator: Unset Gerrit/Stashbot CSS
// @namespace    https://phabricator.wikimedia.org/
// @version      1.0
// @description  Unset/override the bot-related timeline CSS on phabricator.wikimedia.org so those style rules no longer apply.
// @match        https://phabricator.wikimedia.org/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

// https://phabricator.wikimedia.org/T393289
// https://gitlab.wikimedia.org/repos/phabricator/phabricator/-/blob/wmf/stable/webroot/rsrc/css/phui/phui-timeline-view-wikimedia.css

(function () {
  'use strict';

  const css = `
/* Explicit property overrides to undo the listed Phabricator bot-timeline rules. */
/* 1) Avatar / timeline-image positioning and sizing */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"],
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"],
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"],
.device .phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"],
.device .phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"],
.device .phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] {
  background-position: revert !important;
  left: revert !important;
  width: revert !important;
  height: revert !important;
  top: revert !important;
  margin-top: revert !important;
  display: revert !important;
}

/* 2) CodeReviewBot icon size */
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] {
  background-size: revert !important;
}

/* 3) Wedge / title hiding rules */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-wedge,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-wedge,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-wedge {
  display: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-title,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-title,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-title {
  height: revert !important;
  min-height: revert !important;
  padding-top: revert !important;
  padding-bottom: revert !important;
  visibility: revert !important;
  overflow: revert !important;
  z-index: revert !important;
  line-height: revert !important;
}

/* 4) Menu z-index / margin tweaks */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-menu,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-menu,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-menu {
  z-index: revert !important;
  margin-top: revert !important;
}

/* 5) Timestamp position */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-title .phui-timeline-extra,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-title .phui-timeline-extra,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-title .phui-timeline-extra {
  float: revert !important;
  visibility: revert !important;
  padding-left: revert !important;
  padding-right: revert !important;
  margin-right: revert !important;
}

/* 6) Border rearrangement */
.phui-timeline-major-event .phui-timeline-content {
  /* Thinner border for timeline content */
  border-width: 1px !important;
  border-style: solid !important;
  border-color: rgba(0,0,0,0.08) !important;
}
.phui-timeline-major-event .phui-timeline-content .phui-timeline-group {
  border-top: revert !important;
  border-bottom: revert !important;
  border-width: 1px !important;
}

/* 7) Gerrit/Stashbot comment box visuals */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group {
  border-width: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-inner-content,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-inner-content,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-inner-content {
  color: revert !important;
  padding: revert !important;
  padding-left: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-core-content,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-core-content,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-core-content {
  /* Force a white background for core content while keeping other properties reverted */
  background: #ffffff !important;
  margin: revert !important;
  padding: revert !important;
  border: revert !important;
  width: revert !important;
  max-width: revert !important;
  overflow: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-core-content p,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-core-content p,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-core-content p {
  margin: revert !important;
}

/* 8) Comment compacting and hover behavior */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-core-content .transaction-comment,
.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-core-content .transaction-comment,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-core-content .transaction-comment {
  display: revert !important;
  margin-top: revert !important;
  margin-right: revert !important;
  position: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group .phui-timeline-core-content .transaction-comment:hover,
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group .phui-timeline-core-content .transaction-comment:hover {
  color: revert !important;
  cursor: revert !important;
  text-decoration: revert !important;
}

/* 9) Specific link visibility hacks */
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"] ~ .phui-timeline-group p:last-child .remarkup-link:only-child {
  color: revert !important;
  user-select: revert !important;
  position: revert !important;
  top: revert !important;
  left: revert !important;
  right: revert !important;
  bottom: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/CodeReviewBot/"] ~ .phui-timeline-group p:first-child .remarkup-link:before {
  content: revert !important;
  color: revert !important;
  user-select: revert !important;
  position: revert !important;
  top: revert !important;
  left: revert !important;
  right: revert !important;
  bottom: revert !important;
}

/* 10) Stashbot truncated-snippet / hover transition */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phabricator-remarkup {
  display: revert !important;
  grid-template-rows: revert !important;
  grid-template-columns: revert !important;
  clip-path: revert !important;
  transition: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phabricator-remarkup p {
  min-height: revert !important;
  min-width: revert !important;
  white-space: revert !important;
  overflow: revert !important;
  text-overflow: revert !important;
  transition-behavior: revert !important;
}

.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phabricator-remarkup:hover,
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phabricator-remarkup:hover p {
  grid-template-rows: revert !important;
  grid-template-columns: revert !important;
  clip-path: revert !important;
  min-width: revert !important;
  white-space: revert !important;
}

/* 11) Stashbot icon top/extra margin tweaks */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] {
  top: revert !important;
}
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .phui-timeline-title .phui-timeline-extra {
  margin-bottom: revert !important;
}

/* 12) remarkup-nav-sequence link styles */
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .remarkup-nav-sequence:hover,
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .remarkup-nav-sequence,
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .remarkup-nav-sequence *,
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] ~ .phui-timeline-group .remarkup-nav-sequence *:before {
  display: revert !important;
  font-weight: revert !important;
}

/* 13) Icon filter rules */
.phui-timeline-major-event a.phui-timeline-image[href="/p/gerritbot/"],
.phui-timeline-major-event:has(.phui-timeline-group .phui-timeline-core-content .transaction-comment strong) a.phui-timeline-image[href="/p/gerritbot/"],
.phui-timeline-major-event:has(.phui-timeline-group .phui-timeline-core-content .transaction-comment .remarkup-literal ~ .remarkup-literal) a.phui-timeline-image[href="/p/gerritbot/"],
.phui-timeline-major-event a.phui-timeline-image[href="/p/Stashbot/"] {
  filter: revert !important;
}

/* 14) Minor-event hiding rules (undo hide/blur/chevron) */
.phui-timeline-minor-event .phui-timeline-content:has(
  a.phui-timeline-image[href="/p/gerritbot/"],
  a.phui-timeline-image[href="/p/Maintenance_bot/"] ~ .phui-timeline-group a.phui-handle[href="/tag/patch-for-review/"],
  a.phui-timeline-image[href="/p/Stashbot/"]
) {
  visibility: revert !important;
  display: revert !important;
  grid-template-rows: revert !important;
  transition: revert !important;
  white-space: revert !important;
  margin-top: revert !important;
}

.phui-timeline-minor-event .phui-timeline-content:has( > * ) > * {
  opacity: revert !important;
  filter: revert !important;
}

.phui-timeline-minor-event .phui-timeline-content:has(:hover) > * {
  opacity: revert !important;
  filter: revert !important;
}

/* chevron pseudo-element */
.phui-timeline-minor-event .phui-timeline-content::before{
  content: revert !important;
  background: revert !important;
  background-image: revert !important;
  visibility: revert !important;
  height: revert !important;
  width: revert !important;
  position: revert !important;
  margin-left: revert !important;
  margin-top: revert !important;
  transition: revert !important;
}

.phui-timeline-minor-event .phui-timeline-content .phui-timeline-image {
  padding-right: revert !important;
}

/* 15) Avoid overlap tweak (undo extra margin) */
.phui-timeline-minor-event .phui-timeline-content a.phui-timeline-image[href="/p/gerritbot/"],
.phui-timeline-minor-event .phui-timeline-content a.phui-timeline-image[href="/p/Maintenance_bot/"] ~ .phui-timeline-group a.phui-handle[href="/tag/patch-for-review/"],
.phui-timeline-minor-event .phui-timeline-content a.phui-timeline-image[href="/p/Stashbot/"] {
  margin-top: revert !important;
}
  `;

  function injectStyle(cssText) {
    try {
      const style = document.createElement('style');
      style.setAttribute('data-userscript', 'phabricator-unset-bot-css');
      style.textContent = cssText;
      const target = document.head || document.documentElement;
      target.prepend(style);
      // Also try to remove any inline <style> elements that identify themselves (best-effort; non-destructive)
      // (This block is conservative, it will not remove unknown styles.)
      try {
        const existing = document.querySelectorAll('style');
        existing.forEach(s => {
          const attr = s.getAttribute('data-provides') || s.getAttribute('data-phui') || s.id || '';
          if (attr && /phui-timeline-view-wikimedia-css|phui-timeline/.test(attr)) {
            s.remove();
          }
        });
      } catch (e) {
        // ignore
      }
    } catch (e) {
      // If document not ready or other errors, try later
      window.addEventListener('DOMContentLoaded', () => {
        injectStyle(cssText);
      }, { once: true });
    }
  }

  injectStyle(css);
})();
