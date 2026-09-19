#!/bin/bash
set -euo pipefail

ADMIN_DIR="/var/www/html/admin"
LP_FILE="$ADMIN_DIR/taillog.lp"
JS_FILE="$ADMIN_DIR/scripts/js/taillog.js"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "=== Pi-hole Tail Log installer ==="
echo

if [ ! -d "$ADMIN_DIR" ]; then
    echo "ERRO: $ADMIN_DIR não existe."
    exit 1
fi

if [ ! -d "$ADMIN_DIR/scripts/js" ]; then
    echo "ERRO: $ADMIN_DIR/scripts/js não existe."
    exit 1
fi

echo "Criando backups..."
sudo cp "$LP_FILE" "${LP_FILE}.bak-${STAMP}"
sudo cp "$JS_FILE" "${JS_FILE}.bak-${STAMP}"

echo "Gravando taillog.lp..."
sudo tee "$LP_FILE" >/dev/null <<'__TAILLOG_LP__'
<? --[[
*    Pi-hole: A black hole for Internet advertisements
*    (c) 2017 Pi-hole, LLC (https://pi-hole.net)
*    Network-wide ad blocking via your own hardware.
*
*    This file is copyright under the latest version of the EUPL.
*    Please see LICENSE file for your rights under this license.
*/ ]]--

mg.include('scripts/lua/header_authenticated.lp','r')
?>
<!-- Title/Header -->
<div class="app-content-header">
    <div class="container-fluid">
        <div class="row">
            <div class="col-12">
                <h1 class="mb-0">Tail Log</h1>
            </div>
        </div>
    </div>
</div>

<div class="app-content">
    <div class="container-fluid">

    <div class="row">
        <div class="col-md-12">
            <div class="card card-warning card-outline">
                <div
                    class="card-header"
                    style="display: flex; align-items: center; flex-wrap: nowrap;"
                >
                    <h3
                        class="card-title"
                        style="
                            margin: 0;
                            min-width: 0;
                            flex: 1 1 auto;
                            white-space: nowrap;
                            overflow: hidden;
                            text-overflow: ellipsis;
                        "
                    >
                        <code>tail -F <span id="filename">...</span></code>
                    </h3>

                    <div
                        style="
                            display: flex;
                            align-items: center;
                            flex-wrap: nowrap;
                            flex-shrink: 0;
                            margin-left: auto;
                            white-space: nowrap;
                            gap: 0.5rem;
                        "
                    >
                        <span style="white-space: nowrap;">
                            Autoscroll:&nbsp;<i
                                class="fa fa-fw fa-check"
                                id="autoscrolling"
                            ></i>
                        </span>

                        <button
                            type="button"
                            class="btn btn-success"
                            id="live-feed"
                            style="flex-shrink: 0;"
                        >
                            <span id="title">Live</span>&nbsp;&nbsp;
                            <i
                                id="feed-icon"
                                class="fa-solid fa-fw fa-play fa-fade"
                            ></i>
                        </button>

                        <button
                            type="button"
                            class="btn btn-primary d-none"
                            id="export-queries"
                            style="flex-shrink: 0;"
                        >
                            Export queries
                        </button>
                    </div>
                </div>

                <div class="card-body">
                    <div class="row">
                        <div class="col-md-12">
                            <pre id="output" class="pre pre-scrollable pre-taillog"></pre>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    </div><!-- /.container-fluid -->
</div><!-- /.app-content -->

<div
    class="modal fade"
    id="export-queries-modal"
    tabindex="-1"
    aria-labelledby="export-queries-modal-label"
    aria-hidden="true"
>
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5
                    class="modal-title"
                    id="export-queries-modal-label"
                >
                    Export queries
                </h5>

                <button
                    type="button"
                    class="btn-close"
                    id="export-modal-close"
                    aria-label="Close"
                ></button>
            </div>

            <div class="modal-body">
                <h6>Date range</h6>

                <div class="row mb-4">
                    <div class="col-md-6">
                        <label
                            for="export-from"
                            class="form-label"
                        >
                            From
                        </label>

                        <input
                            type="datetime-local"
                            class="form-control"
                            id="export-from"
                        >
                    </div>

                    <div class="col-md-6">
                        <label
                            for="export-until"
                            class="form-label"
                        >
                            Until
                        </label>

                        <input
                            type="datetime-local"
                            class="form-control"
                            id="export-until"
                        >
                    </div>
                </div>

                <h6>Columns</h6>

                <div class="row mb-4">
                    <div class="col-md-4">
                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="timestamp"
                                id="export-column-timestamp"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-timestamp"
                            >
                                Timestamp
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="domain"
                                id="export-column-domain"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-domain"
                            >
                                Domain
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="type"
                                id="export-column-type"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-type"
                            >
                                Type
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="status"
                                id="export-column-status"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-status"
                            >
                                Status
                            </label>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="client_ip"
                                id="export-column-client-ip"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-client-ip"
                            >
                                Client IP
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="client_name"
                                id="export-column-client-name"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-client-name"
                            >
                                Client name
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="reply"
                                id="export-column-reply"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-reply"
                            >
                                Reply
                            </label>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="reply_time"
                                id="export-column-reply-time"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-reply-time"
                            >
                                Reply time
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="dnssec"
                                id="export-column-dnssec"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-dnssec"
                            >
                                DNSSEC
                            </label>
                        </div>

                        <div class="form-check">
                            <input
                                class="form-check-input export-column"
                                type="checkbox"
                                value="upstream"
                                id="export-column-upstream"
                                checked
                            >
                            <label
                                class="form-check-label"
                                for="export-column-upstream"
                            >
                                Upstream
                            </label>
                        </div>
                    </div>
                </div>

                <h6>Options</h6>

                <div class="form-check">
                    <input
                        class="form-check-input"
                        type="checkbox"
                        id="export-remove-duplicates"
                    >
                    <label
                        class="form-check-label"
                        for="export-remove-duplicates"
                    >
                        Remove duplicate queries
                    </label>
                </div>

                <div class="form-text">
                    Duplicate queries are identified by domain and query type. The most recent query is kept.
                </div>

                <div
                    class="alert alert-danger mt-3 d-none"
                    id="export-error"
                    role="alert"
                ></div>
            </div>

            <div class="modal-footer">
                <button
                    type="button"
                    class="btn btn-secondary"
                    id="export-modal-cancel"
                >
                    Cancel
                </button>

                <button
                    type="button"
                    class="btn btn-primary"
                    id="export-confirm"
                >
                    Export
                </button>
            </div>
        </div>
    </div>
</div>

<script src="<?=pihole.fileversion('scripts/js/taillog.js')?>"></script>

<? mg.include('scripts/lua/footer.lp','r')?>
__TAILLOG_LP__

echo "Gravando taillog.js..."
sudo tee "$JS_FILE" >/dev/null <<'__TAILLOG_JS__'
/* Pi-hole: A black hole for Internet advertisements
 *  (c) 2017 Pi-hole, LLC (https://pi-hole.net)
 *  Network-wide ad blocking via your own hardware.
 *
 *  This file is copyright under the latest version of the EUPL.
 *  Please see LICENSE file for your rights under this license. */

/* global moment: false, apiFailure: false, utils: false, REFRESH_INTERVAL: false */

"use strict";

let nextID = 0;
let lastPID = -1;

// Maximum number of lines to display
const maxlines = 5000;

// Fade in new lines
const fadeIn = true;

// Mark new lines with a red line above them
const markUpdates = true;

// Format a line of the dnsmasq log
function formatDnsmasq(line) {
  // Remove dnsmasq + PID
  let txt = line.replaceAll(/ dnsmasq\[\d*\]/gu, "");

  if (line.includes("denied") || line.includes("gravity blocked")) {
    // Red bold text for blocked domains
    txt = `<strong class="log-red">${txt}</strong>`;
  } else if (line.includes("query[A") || line.includes("query[DHCP")) {
    // Bold text for initial query lines
    txt = `<strong>${txt}</strong>`;
  } else {
    // Grey text for all other lines
    txt = `<span class="text-muted">${txt}</span>`;
  }

  return txt;
}

function formatFTL(line, priority) {
  // Colorize priority
  let priorityClass = "";

  switch (priority) {
    case "INFO": {
      priorityClass = "text-success";
      break;
    }

    case "WARNING": {
      priorityClass = "text-warning";
      break;
    }

    case "ERR":
    case "ERROR":
    case "EMERG":
    case "ALERT":
    case "CRIT": {
      priorityClass = "text-danger";
      break;
    }

    default:
      priorityClass = priority.startsWith("DEBUG") ? "text-info" : "text-muted";
  }

  // Return formatted line
  return `<span class="${priorityClass}">${utils.escapeHtml(priority)}</span> ${line}`;
}

function escapeCSV(value) {
  if (value === null || value === undefined) {
    return "";
  }

  const text = String(value);

  if (
    text.includes(",") ||
    text.includes('"') ||
    text.includes("\n") ||
    text.includes("\r")
  ) {
    return `"${text.replaceAll('"', '""')}"`;
  }

  return text;
}

function getExportColumns() {
  const columns = {
    timestamp: {
      header: "timestamp",
      value: query => moment.unix(query.time).format("YYYY-MM-DD HH:mm:ss.SSS"),
    },
    domain: {
      header: "domain",
      value: query => query.domain,
    },
    type: {
      header: "type",
      value: query => query.type,
    },
    status: {
      header: "status",
      value: query => query.status,
    },
    client_ip: {
      header: "client_ip",
      value: query => query.client?.ip,
    },
    client_name: {
      header: "client_name",
      value: query => query.client?.name,
    },
    reply: {
      header: "reply",
      value: query => query.reply?.type,
    },
    reply_time: {
      header: "reply_time",
      value: query => query.reply?.time,
    },
    dnssec: {
      header: "dnssec",
      value: query => query.dnssec,
    },
    upstream: {
      header: "upstream",
      value: query => query.upstream,
    },
  };

  const selectedColumns = [];

  for (const checkbox of document.querySelectorAll(".export-column:checked")) {
    if (columns[checkbox.value]) {
      selectedColumns.push(columns[checkbox.value]);
    }
  }

  return selectedColumns;
}

function removeDuplicateQueries(queries) {
  const latestQueries = new Map();

  for (const query of queries) {
    const key = `${query.domain}\u0000${query.type}`;
    const current = latestQueries.get(key);

    if (!current || query.time > current.time) {
      latestQueries.set(key, query);
    }
  }

  return [...latestQueries.values()].sort((a, b) => b.time - a.time);
}

function showExportError(message) {
  const errorElement = document.getElementById("export-error");

  errorElement.textContent = message;
  errorElement.classList.remove("d-none");
}

function clearExportError() {
  const errorElement = document.getElementById("export-error");

  errorElement.textContent = "";
  errorElement.classList.add("d-none");
}

function formatDateTimeLocal(date) {
  return moment(date).format("YYYY-MM-DDTHH:mm");
}

function setDefaultExportDateRange() {
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  document.getElementById("export-from").value = formatDateTimeLocal(oneDayAgo);
  document.getElementById("export-until").value = formatDateTimeLocal(now);
}

function initializeDateTimePicker(event) {
  const input = event.currentTarget;

  input.dataset.previousValue = input.value;
  input.dataset.hourChanged = "false";
  input.dataset.minuteChanged = "false";
}

function closeDateTimePicker(event) {
  const input = event.currentTarget;

  if (!input.value) {
    input.dataset.previousValue = "";
    return;
  }

  const previousValue = input.dataset.previousValue || input.value;
  const currentValue = input.value;

  const previousDate = previousValue.split("T")[0];
  const currentDate = currentValue.split("T")[0];

  const previousTime = previousValue.split("T")[1] || "";
  const currentTime = currentValue.split("T")[1] || "";

  const previousHour = previousTime.split(":")[0];
  const currentHour = currentTime.split(":")[0];

  const previousMinute = previousTime.split(":")[1];
  const currentMinute = currentTime.split(":")[1];

  if (previousDate !== currentDate) {
    input.dataset.previousValue = currentValue;

    requestAnimationFrame(() => {
      input.blur();
    });

    return;
  }

  if (previousHour !== currentHour) {
    input.dataset.hourChanged = "true";
  }

  if (previousMinute !== currentMinute) {
    input.dataset.minuteChanged = "true";
  }

  input.dataset.previousValue = currentValue;

  if (
    input.dataset.hourChanged === "true" &&
    input.dataset.minuteChanged === "true"
  ) {
    requestAnimationFrame(() => {
      input.blur();
    });
  }
}

function showExportModal() {
  const modalElement = document.getElementById("export-queries-modal");

  if (globalThis.bootstrap?.Modal) {
    const modal = globalThis.bootstrap.Modal.getOrCreateInstance(modalElement);

    modal.show();
    return;
  }

  if (
    globalThis.jQuery &&
    typeof globalThis.jQuery.fn.modal === "function"
  ) {
    globalThis.jQuery(modalElement).modal("show");
    return;
  }

  modalElement.style.display = "block";
  modalElement.classList.add("show");
  modalElement.removeAttribute("aria-hidden");
  modalElement.setAttribute("aria-modal", "true");
  modalElement.setAttribute("role", "dialog");

  document.body.classList.add("modal-open");

  let backdrop = document.getElementById(
    "export-queries-modal-backdrop"
  );

  if (!backdrop) {
    backdrop = document.createElement("div");

    backdrop.id = "export-queries-modal-backdrop";
    backdrop.className = "modal-backdrop fade show";

    backdrop.addEventListener("click", hideExportModal);

    document.body.append(backdrop);
  }
}

function hideExportModal() {
  const modalElement = document.getElementById("export-queries-modal");

  if (globalThis.bootstrap?.Modal) {
    const modal = globalThis.bootstrap.Modal.getInstance(modalElement);

    if (modal) {
      modal.hide();
      return;
    }
  }

  if (
    globalThis.jQuery &&
    typeof globalThis.jQuery.fn.modal === "function"
  ) {
    globalThis.jQuery(modalElement).modal("hide");
    return;
  }

  modalElement.style.display = "none";
  modalElement.classList.remove("show");
  modalElement.setAttribute("aria-hidden", "true");
  modalElement.removeAttribute("aria-modal");
  modalElement.removeAttribute("role");

  document.body.classList.remove("modal-open");

  document
    .getElementById("export-queries-modal-backdrop")
    ?.remove();
}

async function exportQueries() {
  const exportButton = document.getElementById("export-confirm");
  const removeDuplicates =
    document.getElementById("export-remove-duplicates").checked;

  const selectedColumns = getExportColumns();

  clearExportError();

  if (selectedColumns.length === 0) {
    showExportError("Select at least one column to export.");
    return;
  }

  const fromValue = document.getElementById("export-from").value;
  const untilValue = document.getElementById("export-until").value;

  if (!fromValue || !untilValue) {
    showExportError("Select both From and Until dates.");
    return;
  }

  const from = Math.floor(new Date(fromValue).getTime() / 1000);
  const until = Math.floor(new Date(untilValue).getTime() / 1000);

  if (!Number.isFinite(from) || !Number.isFinite(until)) {
    showExportError("Invalid date range.");
    return;
  }

  if (from > until) {
    showExportError("From must be earlier than Until.");
    return;
  }

  const csrfToken = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute("content");

  const pageLength = 1000;
  const queries = [];

  let cursor = null;
  let recordsFiltered = null;

  exportButton.disabled = true;
  exportButton.textContent = "Exporting...";

  try {
    while (true) {
      const url = new URL(
        `${document.body.dataset.apiurl}/queries`,
        globalThis.location.origin
      );

      url.searchParams.set("from", from);
      url.searchParams.set("until", until);
      url.searchParams.set("length", pageLength);
      url.searchParams.set("disk", "true");

      if (cursor !== null) {
        url.searchParams.set("cursor", cursor);
      }

      const response = await fetch(url, {
        method: "GET",
        headers: {
          "X-CSRF-TOKEN": csrfToken,
        },
      });

      if (!response.ok) {
        await apiFailure(response);
        return;
      }

      const data = await response.json();
      const pageQueries = data.queries || [];

      if (recordsFiltered === null) {
        recordsFiltered = data.recordsFiltered;
      }

      queries.push(...pageQueries);

      exportButton.textContent =
        recordsFiltered === null
          ? `Exporting... ${queries.length}`
          : `Exporting... ${queries.length}`;

      if (pageQueries.length === 0) {
        break;
      }

      const nextCursor = data.cursor;

      if (
        nextCursor === null ||
        nextCursor === undefined
      ) {
        break;
      }

      if (cursor !== null && nextCursor === cursor) {
        throw new Error("Query pagination did not advance.");
      }

      cursor = nextCursor;
    }

    let exportQueriesData = queries;

    if (removeDuplicates) {
      exportQueriesData = removeDuplicateQueries(exportQueriesData);
    }

    const headers = selectedColumns.map(column => column.header);

    const rows = exportQueriesData.map(query =>
      selectedColumns.map(column => column.value(query))
    );

    const csv = [
      headers.map(value => escapeCSV(value)).join(","),
      ...rows.map(row =>
        row.map(value => escapeCSV(value)).join(",")
      ),
    ].join("\r\n");

    const blob = new Blob(
      [csv],
      {
        type: "text/csv;charset=utf-8",
      }
    );

    const downloadURL = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = downloadURL;
    link.download = "pihole-query-log.csv";

    document.body.append(link);
    link.click();
    link.remove();

    URL.revokeObjectURL(downloadURL);

    hideExportModal();
  } catch (error) {
    console.error(error);
    showExportError(
      error instanceof Error
        ? error.message
        : "Failed to export queries."
    );
  } finally {
    exportButton.disabled = false;
    exportButton.textContent = "Export";
  }
}

let gAutoScrolling;

// Function that asks the API for new data
function getData() {
  // Only update when the feed icon has the fa-play class
  const feedIcon = document.getElementById("feed-icon");

  if (!feedIcon.classList.contains("fa-play")) {
    utils.setTimer(getData, REFRESH_INTERVAL.logs);
    return;
  }

  const queryParams = utils.parseQueryString();
  const outputElement = document.getElementById("output");
  const allowedFileParams = ["dnsmasq", "ftl", "webserver"];

  // Check if file parameter exists
  if (!queryParams.file) {
    // Add default file parameter and redirect
    const url = new URL(globalThis.location.href);

    url.searchParams.set("file", "dnsmasq");

    globalThis.location.href = url.toString();
    return;
  }

  // Validate that file parameter is one of the allowed values
  if (!allowedFileParams.includes(queryParams.file)) {
    const errorMessage =
      `Invalid file parameter: ${queryParams.file}. ` +
      `Allowed values are: ${allowedFileParams.join(", ")}`;

    outputElement.innerHTML =
      `<div><em class="text-danger">*** Error: ` +
      `${utils.escapeHtml(errorMessage)} ***</em></div>`;

    return;
  }

  const csrfToken = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute("content");

  const url =
    `${document.body.dataset.apiurl}/logs/${queryParams.file}` +
    `?nextID=${nextID}`;

  fetch(url, {
    method: "GET",
    headers: {
      "X-CSRF-TOKEN": csrfToken,
    },
  })
    .then(response =>
      response.ok ? response.json() : apiFailure(response)
    )
    .then(data => {
      // Set filename
      document.getElementById("filename").textContent = data.file;

      // Check if we have a new PID -> FTL was restarted
      if (lastPID !== data.pid) {
        if (lastPID !== -1) {
          outputElement.innerHTML +=
            '<div><em class="text-danger">' +
            "*** FTL restarted ***" +
            "</em></div>";
        }

        // Remember PID
        lastPID = data.pid;

        // Reset nextID
        nextID = 0;

        getData();
        return;
      }

      // Set placeholder text if log file is empty and we have no new lines
      if (data.log.length === 0) {
        if (nextID === 0) {
          outputElement.innerHTML =
            "<div><em>*** Log file is empty ***</em></div>";
        }

        utils.setTimer(getData, REFRESH_INTERVAL.logs);
        return;
      }

      // Create a document fragment to batch the DOM updates
      const fragment = document.createDocumentFragment();

      // We have new lines
      if (markUpdates && nextID > 0) {
        // Add red fading out background to new lines
        const hr = document.createElement("hr");

        hr.className = "hr-small fade-2s";

        fragment.append(hr);
      }

      // Limit output to <maxlines> lines
      // Check if adding these new lines would exceed maxlines
      const totalAfterAdding =
        outputElement.children.length +
        data.log.length +
        (markUpdates && nextID > 0 ? 1 : 0);

      // If we'll exceed maxlines, remove old elements first
      if (totalAfterAdding > maxlines) {
        const elementsToRemove = totalAfterAdding - maxlines;
        const elements = [...outputElement.children];
        const elementsToKeep = elements.slice(elementsToRemove);

        outputElement.replaceChildren(...elementsToKeep);
      }

      for (const line of data.log) {
        // Escape HTML
        line.message = utils.escapeHtml(line.message);

        // Format line if applicable
        if (queryParams.file === "dnsmasq") {
          line.message = formatDnsmasq(line.message);
        } else if (queryParams.file === "ftl") {
          line.message = formatFTL(line.message, line.prio);
        }

        // Create and add new log entry to fragment
        const logEntry = document.createElement("div");

        const logEntryDate = moment(
          1000 * line.timestamp
        ).format("YYYY-MM-DD HH:mm:ss.SSS");

        logEntry.className =
          `log-entry${fadeIn ? " hidden-entry" : ""}`;

        logEntry.innerHTML =
          `<span class="text-muted">${logEntryDate}</span> ` +
          `${line.message}`;

        fragment.append(logEntry);
      }

      // Append all new elements at once
      outputElement.append(fragment);

      if (fadeIn) {
        // Fade in the new log entries
        const newEntries =
          outputElement.querySelectorAll(".hidden-entry");

        for (const entry of newEntries) {
          entry.classList.add("fade-in-transition");
        }

        // Force a reflow once before changing opacity
        void outputElement.offsetWidth; // eslint-disable-line no-void

        requestAnimationFrame(() => {
          for (const entry of newEntries) {
            entry.classList.remove("hidden-entry");
            entry.style.opacity = 1;
          }
        });

        // Clean up after animation completes
        setTimeout(() => {
          for (const entry of newEntries) {
            entry.classList.remove("fade-in-transition");
          }
        }, 200);
      }

      // Scroll to bottom of output if we are already at the bottom
      if (gAutoScrolling) {
        // Auto-scrolling is enabled
        requestAnimationFrame(() => {
          outputElement.scrollTop = outputElement.scrollHeight;
        });
      }

      // Update nextID
      nextID = data.nextID;

      utils.setTimer(getData, REFRESH_INTERVAL.logs);
    })
    .catch(error => {
      apiFailure(error);
      utils.setTimer(getData, 5 * REFRESH_INTERVAL.logs);
    });
}

gAutoScrolling = true;

document.getElementById("output").addEventListener(
  "scroll",
  event => {
    const output = event.currentTarget;

    // Check if we are at the bottom of the output
    //
    // - output.scrollHeight: This gets the entire height of the content
    //   of the "output" element, including the part that is not visible due to
    //   scrolling.
    // - output.clientHeight: This gets the inner height of the "output"
    //   element, which is the visible part of the content.
    // - output.scrollTop: This gets the number of pixels that the content
    //   of the "output" element is scrolled vertically from the top.
    //
    // By subtracting the inner height and the scroll top from the scroll height,
    // you get the distance from the bottom of the scrollable area.

    const {
      scrollHeight,
      clientHeight,
      scrollTop,
    } = output;

    // Add a tolerance of four line heights
    const tolerance =
      4 * Number.parseFloat(
        getComputedStyle(output).lineHeight
      );

    // Determine if the output is scrolled to the bottom within the tolerance
    const isAtBottom =
      scrollHeight - clientHeight - scrollTop <= tolerance;

    gAutoScrolling = isAtBottom;

    const autoScrollingElement =
      document.getElementById("autoscrolling");

    if (isAtBottom) {
      autoScrollingElement.classList.add("fa-check");
      autoScrollingElement.classList.remove("fa-xmark");
    } else {
      autoScrollingElement.classList.add("fa-xmark");
      autoScrollingElement.classList.remove("fa-check");
    }
  },
  { passive: true }
);

$(() => {
  getData();

  const liveFeed = document.getElementById("live-feed");
  const feedIcon = document.getElementById("feed-icon");
  const title = document.getElementById("title");

  const exportQueriesButton =
    document.getElementById("export-queries");

  const exportConfirm =
    document.getElementById("export-confirm");

  const exportModalClose =
    document.getElementById("export-modal-close");

  const exportModalCancel =
    document.getElementById("export-modal-cancel");

  const exportFrom =
    document.getElementById("export-from");

  const exportUntil =
    document.getElementById("export-until");

  const queryParams = utils.parseQueryString();

  if (queryParams.file === "dnsmasq") {
    exportQueriesButton.classList.remove("d-none");

    exportQueriesButton.addEventListener("click", () => {
      setDefaultExportDateRange();
      clearExportError();
      showExportModal();
    });
  }

  exportModalClose.addEventListener(
    "click",
    hideExportModal
  );

  exportModalCancel.addEventListener(
    "click",
    hideExportModal
  );

  exportConfirm.addEventListener(
    "click",
    exportQueries
  );

  exportFrom.addEventListener(
    "focus",
    initializeDateTimePicker
  );

  exportUntil.addEventListener(
    "focus",
    initializeDateTimePicker
  );

  exportFrom.addEventListener(
    "input",
    closeDateTimePicker
  );

  exportUntil.addEventListener(
    "input",
    closeDateTimePicker
  );

  // Clicking on the element with ID "live-feed" will toggle the play/pause state
  liveFeed.addEventListener("click", event => {
    // Determine current state based on whether feedIcon has the "fa-play" class
    const isPlaying =
      feedIcon.classList.contains("fa-play");

    if (isPlaying) {
      feedIcon.classList.add("fa-pause");
      feedIcon.classList.remove("fa-fade", "fa-play");

      event.currentTarget.classList.add("btn-danger");
      event.currentTarget.classList.remove("btn-success");

      title.textContent = "Paused";
    } else {
      feedIcon.classList.add("fa-play", "fa-fade");

      event.currentTarget.classList.add("btn-success");
      event.currentTarget.classList.remove("btn-danger");

      title.textContent = "Live";
    }
  });
});
__TAILLOG_JS__

sudo chown root:root "$LP_FILE" "$JS_FILE"
sudo chmod 644 "$LP_FILE" "$JS_FILE"

echo
echo "=== VALIDAÇÃO ==="

if grep -RnE '^(<<<<<<<|=======|>>>>>>>)' "$LP_FILE" "$JS_FILE"; then
    echo "ERRO: marcadores de conflito encontrados."
    exit 1
fi

grep -q 'id="export-queries"' "$LP_FILE" || {
    echo "ERRO: Export Queries não encontrado no taillog.lp."
    exit 1
}

grep -q 'async function exportQueries()' "$JS_FILE" || {
    echo "ERRO: exportQueries() não encontrado no taillog.js."
    exit 1
}

grep -q 'function getData()' "$JS_FILE" || {
    echo "ERRO: getData() não encontrado no taillog.js."
    exit 1
}

grep -q 'const nextCursor = data.cursor;' "$JS_FILE" || {
    echo "ERRO: paginação não está usando o cursor retornado pela API."
    exit 1
}

if grep -q 'lastQuery.id - 1' "$JS_FILE"; then
    echo "ERRO: paginação antiga por query.id ainda existe."
    exit 1
fi

if grep -q '<div class="app-content"' "$JS_FILE"; then
    echo "ERRO: HTML encontrado dentro do taillog.js."
    exit 1
fi

echo "OK: arquivos instalados."
echo
echo "Linhas:"
wc -l "$LP_FILE" "$JS_FILE"
echo
echo "Paginação:"
grep -n 'nextCursor = data.cursor' "$JS_FILE"
echo
echo "Backups:"
echo "${LP_FILE}.bak-${STAMP}"
echo "${JS_FILE}.bak-${STAMP}"
echo
echo "Faça Ctrl+F5 no navegador antes de testar."
