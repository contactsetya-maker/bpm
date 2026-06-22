#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>
#include <limits.h>

// Color UI macros
#define RED     "\033[0;31m"
#define GREEN   "\033[0;32m"
#define YELLOW  "\033[0;33m"
#define BLUE    "\033[0;34m"
#define BOLD    "\033[1m"
#define NC      "\033[0m"

#define log_info(fmt, ...)    fprintf(stderr, BLUE BOLD "[BPM] " NC fmt "\n", ##__VA_ARGS__)
#define log_success(fmt, ...) fprintf(stderr, GREEN BOLD "[BPM]✓ " NC fmt "\n", ##__VA_ARGS__)
#define log_warn(fmt, ...)    fprintf(stderr, YELLOW BOLD "[BPM]! " NC fmt "\n", ##__VA_ARGS__)
#define log_error(fmt, ...)   fprintf(stderr, RED BOLD "[BPM]✗ Error: " NC fmt "\n", ##__VA_ARGS__)

// Global Paths
char bpm_dir[PATH_MAX];
char plugins_dir[PATH_MAX];

void print_usage() {
    printf("bpm-c - High-Performance Native Bash Plugin Manager\n\n"
           "Usage:\n"
           "  bpm load <repo> [options]  - Install and generate source target\n"
           "  bpm init-ble               - Pre-initialize ble.sh\n"
           "  bpm finalize-ble           - Attach ble.sh terminal engine\n"
           "  bpm update [<repo>]        - Update plugins in parallel\n"
           "  bpm list                   - List active plugins\n"
           "  bpm clean                  - Prune/optimize repositories\n"
           "  bpm ui                     - Launch fallback interactive manager\n\n"
           "Options for 'load':\n"
           "  --use <filename>           - Explicitly target this file to source\n"
           "  --on <command>             - Run post-install compilation hook\n"
           "  --branch <name>            - Target a specific branch/tag/commit\n");
}

// Ensure base management paths exist
void init_paths() {
    const char *env_bpm = getenv("BPM_DIR");
    if (env_bpm) {
        strncpy(bpm_dir, env_bpm, sizeof(bpm_dir) - 1);
    } else {
        const char *home = getenv("HOME");
        snprintf(bpm_dir, sizeof(bpm_dir), "%s/.local/share/bpm", home ? home : ".");
    }
    snprintf(plugins_dir, sizeof(plugins_dir), "%s/plugins", bpm_dir);

    // Create directories (mkdir -p logic via recursive matching isn't fully expanded here for simplicity)
    mkdir(bpm_dir, 0755);
    mkdir(plugins_dir, 0755);
}

// Resolve final entry-point script
void find_entry_point(const char *dir, const char *custom_use, char *out_path, size_t max_len) {
    if (custom_use && strlen(custom_use) > 0) {
        snprintf(out_path, max_len, "%s/%s", dir, custom_use);
        if (access(out_path, F_OK) == 0) return;
    }

    // Dynamic search fallback array
    const char *repo_name = strrchr(dir, '/');
    repo_name = repo_name ? repo_name + 1 : dir;

    const char *candidates[] = {
        ".plugin.bash", ".bash", ".sh", "/init.bash", "/init.sh", "/plugin.bash"
    };
    
    // Exact dynamic structures
    char test_path[PATH_MAX];
    for (int i = 0; i < 3; i++) {
        snprintf(test_path, sizeof(test_path), "%s/%s%s", dir, repo_name, candidates[i]);
        if (access(test_path, F_OK) == 0) { strncpy(out_path, test_path, max_len); return; }
    }
    for (int i = 3; i < 6; i++) {
        snprintf(test_path, sizeof(test_path), "%s%s", dir, candidates[i]);
        if (access(test_path, F_OK) == 0) { strncpy(out_path, test_path, max_len); return; }
    }

    // Direct structural search
    DIR *d = opendir(dir);
    if (d) {
        struct dirent *entry;
        while ((entry = readdir(d))) {
            if (strstr(entry->d_name, ".bash") || strstr(entry->d_name, ".sh")) {
                snprintf(out_path, max_len, "%s/%s", dir, entry->d_name);
                closedir(d);
                return;
            }
        }
        closedir(d);
    }
    out_path[0] = '\0';
}

int run_command(const char *cmd) {
    return system(cmd);
}

int cmd_load(int argc, char **argv) {
    char *repo = NULL, *use_file = NULL, *hook = NULL, *branch = NULL;

    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--use") == 0 && i + 1 < argc) use_file = argv[++i];
        else if (strcmp(argv[i], "--on") == 0 && i + 1 < argc) hook = argv[++i];
        else if (strcmp(argv[i], "--branch") == 0 && i + 1 < argc) branch = argv[++i];
        else if (argv[i][0] == '-') { log_error("Unknown option %s", argv[i]); return 1; }
        else repo = argv[i];
    }

    if (!repo) { log_error("No repository specified."); return 1; }

    char dest_dir[PATH_MAX];
    const char *slash = strchr(repo, '/');
    snprintf(dest_dir, sizeof(dest_dir), "%s/%s", plugins_dir, slash ? slash + 1 : repo);

    if (access(dest_dir, F_OK) != 0) {
        log_info("Cloning %s...", repo);
        char cmd[PATH_MAX * 2];
        if (branch) {
            snprintf(cmd, sizeof(cmd), "git clone --depth 1 --branch '%s' 'https://github.com/%s.git' '%s' >/dev/null 2>&1", branch, repo, dest_dir);
        } else {
            snprintf(cmd, sizeof(cmd), "git clone --depth 1 'https://github.com/%s.git' '%s' >/dev/null 2>&1", repo, dest_dir);
        }

        if (run_command(cmd) != 0) {
            log_error("Failed cloning %s", repo);
            return 1;
        }

        if (hook) {
            log_info("Running post-install hook for %s...", repo);
            snprintf(cmd, sizeof(cmd), "cd '%s' && %s", dest_dir, hook);
            if (run_command(cmd) != 0) log_warn("Hook failed for %s", repo);
        }
        log_success("Loaded %s", repo);
    }

    char entry[PATH_MAX];
    find_entry_point(dest_dir, use_file, entry, sizeof(entry));
    if (strlen(entry) > 0) {
        // Output evaluation string back to standard shell router execution
        printf("source \"%s\";\n", entry);
    } else {
        log_warn("Could not resolve valid shell entry file in %s", repo);
    }
    return 0;
}

int cmd_list() {
    DIR *dir = opendir(plugins_dir);
    if (!dir) return 1;
    
    printf(BOLD "Managed Plugins:\n" NC);
    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (entry->d_name[0] == '.') continue;
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/%s", plugins_dir, entry->d_name);
        
        struct stat st;
        if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
            char cmd[PATH_MAX], branch[128] = "local/custom";
            snprintf(cmd, sizeof(cmd), "git -C '%s' branch --show-current 2>/dev/null", path);
            FILE *fp = popen(cmd, "r");
            if (fp) {
                if (fgets(branch, sizeof(branch), fp)) {
                    branch[strcspn(branch, "\n")] = 0;
                }
                pclose(fp);
            }
            printf("  " BLUE "*" NC " %s [branch: %s]\n", entry->d_name, branch);
        }
    }
    closedir(dir);
    return 0;
}

int cmd_update(int argc, char **argv) {
    // Basic single/parallel sync
    if (argc > 2) {
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/%s", plugins_dir, argv[2]);
        if (access(path, F_OK) == 0) {
            char cmd[PATH_MAX];
            snprintf(cmd, sizeof(cmd), "cd '%s' && git fetch --depth 1 origin && git reset --hard origin/$(git branch --show-current)", path);
            return run_command(cmd);
        }
        log_error("Plugin '%s' not found.", argv[2]);
        return 1;
    }

    log_info("Updating all plugins concurrently...");
    DIR *dir = opendir(plugins_dir);
    if (!dir) return 1;

    struct dirent *entry;
    int process_count = 0;
    while ((entry = readdir(dir))) {
        if (entry->d_name[0] == '.') continue;
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/%s", plugins_dir, entry->d_name);

        if (fork() == 0) { // Child Process Execution
            char cmd[PATH_MAX];
            snprintf(cmd, sizeof(cmd), "cd '%s' && git fetch --depth 1 origin && git reset --hard origin/$(git branch --show-current) >/dev/null 2>&1", path);
            int res = system(cmd);
            if (res == 0) printf(GREEN "Updated %s\n" NC, entry->d_name);
            exit(res);
        }
        process_count++;
    }
    closedir(dir);

    while (process_count > 0) { wait(NULL); process_count--; }
    log_success("All updates completed.");
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        print_usage();
        return 0;
    }

    init_paths();

    if (strcmp(argv[1], "load") == 0)         return cmd_load(argc, argv);
    else if (strcmp(argv[1], "list") == 0)    return cmd_list();
    else if (strcmp(argv[1], "update") == 0)  return cmd_update(argc, argv);
    // Extra actions such as init-ble can output strings to handle parent process evaluation
    else if (strcmp(argv[1], "init-ble") == 0) {
        printf("if [[ -f \"%s/ble.sh/share/ble/ble.sh\" ]]; then source \"%s/ble.sh/share/ble/ble.sh\" --noattach; fi\n", plugins_dir, plugins_dir);
        return 0;
    }
    else if (strcmp(argv[1], "finalize-ble") == 0) {
        printf("if type ble-attach &>/dev/null; then ble-attach; fi\n");
        return 0;
    }
    else {
        print_usage();
    }
    return 0;
}
