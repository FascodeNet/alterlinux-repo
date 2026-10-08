#!/usr/bin/env bash
set -euo pipefail
root=${1:?}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat >"$work/check.c" <<'C'
#include <curl/curl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(void) {
    char host[256], url[300];
    if (gethostname(host, sizeof(host))) return 1;
    snprintf(url, sizeof(url), "http://%s:1/", host);
    if (curl_global_init(CURL_GLOBAL_DEFAULT)) return 2;
    CURLM *multi = curl_multi_init();
    CURL *easy = curl_easy_init();
    if (!multi || !easy) return 3;
    curl_easy_setopt(easy, CURLOPT_URL, url);
    curl_easy_setopt(easy, CURLOPT_PROXY, "");
    curl_easy_setopt(easy, CURLOPT_TIMEOUT_MS, 3000L);
    curl_multi_add_handle(multi, easy);
    int running = 1;
    while (running) {
        if (curl_multi_perform(multi, &running)) return 4;
        if (running && curl_multi_poll(multi, NULL, 0, 100, NULL)) return 5;
    }
    curl_multi_remove_handle(multi, easy);
    curl_easy_cleanup(easy);
    pid_t child = fork();
    if (child < 0) return 6;
    if (!child) {
        alarm(3);
        _exit(curl_multi_cleanup(multi) == CURLM_OK ? 0 : 7);
    }
    int status;
    if (waitpid(child, &status, 0) != child) return 8;
    curl_multi_cleanup(multi);
    curl_global_cleanup();
    if (!WIFEXITED(status) || WEXITSTATUS(status)) {
        fprintf(stderr, "curl cleanup after fork failed: %d\n", status);
        return 9;
    }
    puts("curl cleanup after fork passed");
    return 0;
}
C
cc -I"$root/include" "$work/check.c" -L"$root/lib/.libs" -lcurl -o "$work/check"
LD_LIBRARY_PATH="$root/lib/.libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$work/check"
