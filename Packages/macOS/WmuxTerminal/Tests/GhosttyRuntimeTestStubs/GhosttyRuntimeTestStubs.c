#include "include/GhosttyRuntimeTestStubs.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <time.h>

typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} GhosttyRuntimeTestColor;

typedef struct {
    GhosttyRuntimeTestColor foreground;
    bool has_foreground;
    uint32_t diagnostics_count;
} GhosttyRuntimeTestConfig;

static bool wmux_test_needs_confirm_quit = false;
static uint64_t wmux_test_foreground_pid = 0;
static const char* wmux_test_tty_name = NULL;
static uint32_t wmux_test_tty_name_call_count = 0;
static void* wmux_test_renderer_realized_target = NULL;
static bool wmux_test_renderer_realized_calls[16];
static uint32_t wmux_test_renderer_realized_call_count = 0;
static uint32_t wmux_test_renderer_rebuild_call_count = 0;
static bool wmux_test_renderer_realized_result = true;
static bool wmux_test_renderer_occlusion_visible = true;
static bool wmux_test_renderer_release_was_occluded = false;
static void* wmux_test_last_updated_surface = NULL;
static void* wmux_test_font_surface = NULL;
static float wmux_test_font_runtime_points = 0;
static float wmux_test_font_configured_runtime_points = 0;
static bool wmux_test_font_adjusted = false;
static bool wmux_test_font_binding_succeeds = true;
static void* wmux_test_font_callback_surface = NULL;
static ghostty_font_size_action_cb wmux_test_font_callback = NULL;
static void* wmux_test_font_callback_userdata = NULL;
static bool wmux_test_surface_key_called = false;
static int wmux_test_surface_key_mods_value = 0;
static uint32_t wmux_test_surface_key_unshifted_codepoint_value = 0;
static char wmux_test_surface_key_text_value[32];
static int wmux_test_input_event_kinds[32];
static uint32_t wmux_test_input_event_count_value = 0;
static pthread_mutex_t wmux_test_surface_free_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t wmux_test_surface_free_condition = PTHREAD_COND_INITIALIZER;
static bool wmux_test_surface_free_should_block = false;
static bool wmux_test_surface_free_started = false;
static bool wmux_test_surface_free_released = false;
static void* wmux_test_surface_free_target = NULL;
static pthread_mutex_t wmux_test_process_output_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t wmux_test_process_output_condition = PTHREAD_COND_INITIALIZER;
static bool wmux_test_process_output_should_block = false;
static bool wmux_test_process_output_started = false;
static bool wmux_test_process_output_released = false;
static bool wmux_test_process_output_called_on_main = false;
static void* wmux_test_process_output_target = NULL;

typedef struct {
    void* surface;
    bool modes[8];
} GhosttyRuntimeTestTerminalModes;

static GhosttyRuntimeTestTerminalModes wmux_test_terminal_modes[32];
static const int wmux_test_terminal_mode_numbers[8] = {
    1000, 1002, 1003, 1004, 1005, 1006, 1015, 1016,
};

static GhosttyRuntimeTestTerminalModes* wmux_test_terminal_modes_for(void* surface) {
    for (size_t index = 0; index < sizeof(wmux_test_terminal_modes) / sizeof(wmux_test_terminal_modes[0]); index++) {
        if (wmux_test_terminal_modes[index].surface == surface) {
            return &wmux_test_terminal_modes[index];
        }
    }
    for (size_t index = 0; index < sizeof(wmux_test_terminal_modes) / sizeof(wmux_test_terminal_modes[0]); index++) {
        if (wmux_test_terminal_modes[index].surface == NULL) {
            wmux_test_terminal_modes[index].surface = surface;
            memset(wmux_test_terminal_modes[index].modes, 0, sizeof(wmux_test_terminal_modes[index].modes));
            return &wmux_test_terminal_modes[index];
        }
    }
    return NULL;
}

static void wmux_test_terminal_modes_apply(void* surface, const char* data, uintptr_t len) {
    GhosttyRuntimeTestTerminalModes* state = wmux_test_terminal_modes_for(surface);
    if (state == NULL || data == NULL) return;
    for (uintptr_t index = 0; index + 4 < len; index++) {
        if ((unsigned char)data[index] != 0x1b
            || data[index + 1] != '['
            || data[index + 2] != '?') continue;
        uintptr_t cursor = index + 3;
        int mode = 0;
        while (cursor < len && data[cursor] >= '0' && data[cursor] <= '9') {
            mode = mode * 10 + (data[cursor] - '0');
            cursor += 1;
        }
        if (cursor >= len || (data[cursor] != 'h' && data[cursor] != 'l')) continue;
        for (size_t modeIndex = 0; modeIndex < sizeof(wmux_test_terminal_mode_numbers) / sizeof(wmux_test_terminal_mode_numbers[0]); modeIndex++) {
            if (wmux_test_terminal_mode_numbers[modeIndex] == mode) {
                state->modes[modeIndex] = data[cursor] == 'h';
                break;
            }
        }
        index = cursor;
    }
}

void wmux_test_ghostty_surface_terminal_modes_reset(void *surface) {
    GhosttyRuntimeTestTerminalModes* state = wmux_test_terminal_modes_for(surface);
    if (state != NULL) memset(state->modes, 0, sizeof(state->modes));
}

bool wmux_test_ghostty_surface_terminal_mode_enabled(void *surface, int mode) {
    GhosttyRuntimeTestTerminalModes* state = wmux_test_terminal_modes_for(surface);
    if (state == NULL) return false;
    for (size_t index = 0; index < sizeof(wmux_test_terminal_mode_numbers) / sizeof(wmux_test_terminal_mode_numbers[0]); index++) {
        if (wmux_test_terminal_mode_numbers[index] == mode) return state->modes[index];
    }
    return false;
}

typedef void (*GhosttyRuntimeTestRenderPresentedCallback)(void*, uint64_t);
typedef void (*GhosttyRuntimeTestRenderFailedCallback)(void*, uint64_t, int);
typedef struct {
    void* surface;
    GhosttyRuntimeTestRenderPresentedCallback presented;
    void* presented_userdata;
    GhosttyRuntimeTestRenderFailedCallback failed;
    void* failed_userdata;
    uint64_t pending_token;
    bool has_pending_token;
} GhosttyRuntimeTestRenderCallbacks;

static GhosttyRuntimeTestRenderCallbacks wmux_test_render_callbacks[32];

static GhosttyRuntimeTestRenderCallbacks* wmux_test_render_callbacks_for(void* surface) {
    for (size_t index = 0; index < sizeof(wmux_test_render_callbacks) / sizeof(wmux_test_render_callbacks[0]); index++) {
        if (wmux_test_render_callbacks[index].surface == surface) {
            return &wmux_test_render_callbacks[index];
        }
    }
    for (size_t index = 0; index < sizeof(wmux_test_render_callbacks) / sizeof(wmux_test_render_callbacks[0]); index++) {
        if (wmux_test_render_callbacks[index].surface == NULL) {
            wmux_test_render_callbacks[index].surface = surface;
            return &wmux_test_render_callbacks[index];
        }
    }
    return NULL;
}

static void wmux_test_render_callbacks_clear(void* surface) {
    for (size_t index = 0; index < sizeof(wmux_test_render_callbacks) / sizeof(wmux_test_render_callbacks[0]); index++) {
        if (wmux_test_render_callbacks[index].surface == surface) {
            memset(&wmux_test_render_callbacks[index], 0, sizeof(wmux_test_render_callbacks[index]));
            return;
        }
    }
}

static struct timespec wmux_test_surface_free_timeout(void) {
    return (struct timespec) {
        .tv_sec = 5,
        .tv_nsec = 0,
    };
}

void wmux_test_ghostty_runtime_stubs_reset(void) {
    wmux_test_needs_confirm_quit = false;
    wmux_test_foreground_pid = 0;
    wmux_test_tty_name = NULL;
    wmux_test_tty_name_call_count = 0;
    wmux_test_surface_key_called = false;
    wmux_test_surface_key_mods_value = 0;
    wmux_test_surface_key_unshifted_codepoint_value = 0;
    wmux_test_surface_key_text_value[0] = '\0';
    wmux_test_input_event_count_value = 0;
}

void wmux_test_ghostty_surface_key_reset(void) {
    wmux_test_surface_key_called = false;
    wmux_test_surface_key_mods_value = 0;
    wmux_test_surface_key_unshifted_codepoint_value = 0;
    wmux_test_surface_key_text_value[0] = '\0';
}

bool wmux_test_ghostty_surface_key_was_called(void) {
    return wmux_test_surface_key_called;
}

int wmux_test_ghostty_surface_key_mods(void) {
    return wmux_test_surface_key_mods_value;
}

uint32_t wmux_test_ghostty_surface_key_unshifted_codepoint(void) {
    return wmux_test_surface_key_unshifted_codepoint_value;
}

const char* wmux_test_ghostty_surface_key_text(void) {
    return wmux_test_surface_key_text_value;
}

void wmux_test_ghostty_input_events_reset(void) {
    wmux_test_input_event_count_value = 0;
}

uint32_t wmux_test_ghostty_input_event_count(void) {
    return wmux_test_input_event_count_value;
}

int wmux_test_ghostty_input_event_kind(uint32_t index) {
    if (index >= wmux_test_input_event_count_value) return 0;
    return wmux_test_input_event_kinds[index];
}

void wmux_test_ghostty_surface_free_blocking_begin(void *surface) {
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    wmux_test_surface_free_should_block = true;
    wmux_test_surface_free_started = false;
    wmux_test_surface_free_released = false;
    wmux_test_surface_free_target = surface;
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);
}

bool wmux_test_ghostty_surface_free_wait_until_started(void) {
    const struct timespec timeout = wmux_test_surface_free_timeout();
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    while (!wmux_test_surface_free_started) {
        const int result = pthread_cond_timedwait_relative_np(
            &wmux_test_surface_free_condition,
            &wmux_test_surface_free_mutex,
            &timeout
        );
        if (result != 0) break;
    }
    const bool started = wmux_test_surface_free_started;
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);
    return started;
}

bool wmux_test_ghostty_surface_free_blocking_did_start(void) {
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    const bool started = wmux_test_surface_free_started;
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);
    return started;
}

bool wmux_test_ghostty_surface_free_blocking_is_active(void) {
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    const bool active =
        wmux_test_surface_free_should_block
        && wmux_test_surface_free_started
        && !wmux_test_surface_free_released
        && wmux_test_surface_free_target != NULL;
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);
    return active;
}

void wmux_test_ghostty_surface_free_release(void) {
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    wmux_test_surface_free_released = true;
    pthread_cond_broadcast(&wmux_test_surface_free_condition);
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);
}

void wmux_test_ghostty_surface_free_blocking_reset(void) {
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    wmux_test_surface_free_should_block = false;
    wmux_test_surface_free_started = false;
    wmux_test_surface_free_released = true;
    wmux_test_surface_free_target = NULL;
    pthread_cond_broadcast(&wmux_test_surface_free_condition);
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);
}

void wmux_test_ghostty_process_output_blocking_begin(void *surface) {
    pthread_mutex_lock(&wmux_test_process_output_mutex);
    wmux_test_process_output_should_block = true;
    wmux_test_process_output_started = false;
    wmux_test_process_output_released = false;
    wmux_test_process_output_called_on_main = false;
    wmux_test_process_output_target = surface;
    pthread_mutex_unlock(&wmux_test_process_output_mutex);
}

bool wmux_test_ghostty_process_output_wait_until_started(void) {
    const struct timespec timeout = wmux_test_surface_free_timeout();
    pthread_mutex_lock(&wmux_test_process_output_mutex);
    while (!wmux_test_process_output_started) {
        const int result = pthread_cond_timedwait_relative_np(
            &wmux_test_process_output_condition,
            &wmux_test_process_output_mutex,
            &timeout
        );
        if (result != 0) break;
    }
    const bool started = wmux_test_process_output_started;
    pthread_mutex_unlock(&wmux_test_process_output_mutex);
    return started;
}

bool wmux_test_ghostty_process_output_called_on_main_thread(void) {
    pthread_mutex_lock(&wmux_test_process_output_mutex);
    const bool called_on_main = wmux_test_process_output_called_on_main;
    pthread_mutex_unlock(&wmux_test_process_output_mutex);
    return called_on_main;
}

void wmux_test_ghostty_process_output_release(void) {
    pthread_mutex_lock(&wmux_test_process_output_mutex);
    wmux_test_process_output_released = true;
    pthread_cond_broadcast(&wmux_test_process_output_condition);
    pthread_mutex_unlock(&wmux_test_process_output_mutex);
}

void wmux_test_ghostty_process_output_blocking_reset(void) {
    pthread_mutex_lock(&wmux_test_process_output_mutex);
    wmux_test_process_output_should_block = false;
    wmux_test_process_output_started = false;
    wmux_test_process_output_released = true;
    wmux_test_process_output_called_on_main = false;
    wmux_test_process_output_target = NULL;
    pthread_cond_broadcast(&wmux_test_process_output_condition);
    pthread_mutex_unlock(&wmux_test_process_output_mutex);
}

void wmux_test_ghostty_renderer_realized_begin(void* surface) {
    wmux_test_renderer_realized_target = surface;
    wmux_test_renderer_realized_call_count = 0;
    wmux_test_renderer_rebuild_call_count = 0;
    wmux_test_renderer_realized_result = true;
    wmux_test_renderer_occlusion_visible = true;
    wmux_test_renderer_release_was_occluded = false;
}

void wmux_test_ghostty_renderer_realized_reset(void) {
    wmux_test_renderer_realized_target = NULL;
    wmux_test_renderer_realized_call_count = 0;
    wmux_test_renderer_rebuild_call_count = 0;
    wmux_test_renderer_realized_result = true;
    wmux_test_renderer_occlusion_visible = true;
    wmux_test_renderer_release_was_occluded = false;
}

bool wmux_test_ghostty_renderer_occlusion_visible(void) {
    return wmux_test_renderer_occlusion_visible;
}

void wmux_test_ghostty_runtime_stubs_set_close_state(bool needs_confirm, uint64_t foreground_pid, const char* tty_name) {
    wmux_test_needs_confirm_quit = needs_confirm;
    wmux_test_foreground_pid = foreground_pid;
    wmux_test_tty_name = tty_name;
}

uint32_t wmux_test_ghostty_renderer_realized_call_count(void) {
    return wmux_test_renderer_realized_call_count;
}

uint32_t wmux_test_ghostty_renderer_rebuild_call_count(void) {
    return wmux_test_renderer_rebuild_call_count;
}

bool wmux_test_ghostty_renderer_realized_call_value(uint32_t index) {
    if (index >= wmux_test_renderer_realized_call_count) return false;
    return wmux_test_renderer_realized_calls[index];
}

void wmux_test_ghostty_renderer_realized_set_result(bool result) {
    wmux_test_renderer_realized_result = result;
}

bool wmux_test_ghostty_renderer_release_was_occluded(void) {
    return wmux_test_renderer_release_was_occluded;
}

bool ghostty_surface_clear_selection(void *surface) {
    (void)surface;
    return false;
}

bool ghostty_surface_read_selection_clipboard_text(
    void *surface,
    uintptr_t max_bytes,
    ghostty_text_s *selection
) {
    (void)surface;
    (void)max_bytes;
    if (selection != NULL) {
        *selection = (ghostty_text_s){0};
    }
    return false;
}

// GhosttyRuntimeCInterop.initialize() in WmuxTerminalCore references
// ghostty_init directly, so this test runner needs a definition to link.
int ghostty_init(uintptr_t argc, char **argv) {
    (void)argc;
    (void)argv;
    return 0;
}

void *ghostty_config_new(void) {
    return calloc(1, sizeof(GhosttyRuntimeTestConfig));
}

void ghostty_config_free(void *config) {
    free(config);
}

void ghostty_config_load_string(
    void *raw_config,
    const char *contents,
    uintptr_t contents_len,
    const char *path
) {
    (void)contents_len;
    (void)path;
    GhosttyRuntimeTestConfig *config = raw_config;
    const char *value = strchr(contents, '=');
    if (config == NULL || value == NULL) return;
    do { value++; } while (*value == ' ' || *value == '\t');

    if (strcasecmp(value, "black") == 0) {
        config->foreground = (GhosttyRuntimeTestColor){0, 0, 0};
        config->has_foreground = true;
        return;
    }

    config->diagnostics_count = 1;
}

ghostty_string_s ghostty_config_serialize(void *raw_config) {
    const GhosttyRuntimeTestConfig *config = raw_config;
    if (config == NULL) {
        return (ghostty_string_s){0};
    }

    const int length = snprintf(
        NULL,
        0,
        "foreground=%u,%u,%u;has=%u;diagnostics=%u",
        config->foreground.r,
        config->foreground.g,
        config->foreground.b,
        (unsigned)config->has_foreground,
        config->diagnostics_count
    );
    if (length < 0) {
        return (ghostty_string_s){0};
    }
    char *serialized = malloc((size_t)length + 1);
    if (serialized == NULL) {
        return (ghostty_string_s){0};
    }
    snprintf(
        serialized,
        (size_t)length + 1,
        "foreground=%u,%u,%u;has=%u;diagnostics=%u",
        config->foreground.r,
        config->foreground.g,
        config->foreground.b,
        (unsigned)config->has_foreground,
        config->diagnostics_count
    );
    return (ghostty_string_s){
        .ptr = serialized,
        .len = (uintptr_t)length,
        .sentinel = true,
    };
}

bool ghostty_config_get(
    void *raw_config,
    void *raw_value,
    const char *key,
    uintptr_t key_len
) {
    GhosttyRuntimeTestConfig *config = raw_config;
    if (config == NULL || raw_value == NULL || !config->has_foreground ||
        key_len != strlen("foreground") || strncmp(key, "foreground", key_len) != 0) {
        return false;
    }
    *(GhosttyRuntimeTestColor *)raw_value = config->foreground;
    return true;
}

uint32_t ghostty_config_diagnostics_count(void *raw_config) {
    GhosttyRuntimeTestConfig *config = raw_config;
    return config == NULL ? 0 : config->diagnostics_count;
}

void ghostty_config_get_diagnostic(void) {}
void ghostty_string_free(ghostty_string_s string) {
    if (string.sentinel) {
        free((void *)string.ptr);
    }
}
bool ghostty_surface_binding_action(
    void *surface,
    const char *action,
    uintptr_t action_len
) {
    if (surface == wmux_test_font_surface) {
        if (!wmux_test_font_binding_succeeds) return false;
        const float previous_points =
            wmux_test_font_runtime_points;
        const bool previous_adjusted =
            wmux_test_font_adjusted;
        int32_t observed_action = -1;
        char buffer[128];
        const uintptr_t copy_len =
            action_len < sizeof(buffer) - 1
                ? action_len
                : sizeof(buffer) - 1;
        memcpy(buffer, action, copy_len);
        buffer[copy_len] = '\0';
        const char *set_prefix = "set_font_size:";
        if (strncmp(
                buffer,
                set_prefix,
                strlen(set_prefix)
            ) == 0) {
            wmux_test_font_runtime_points =
                strtof(buffer + strlen(set_prefix), NULL);
            if (wmux_test_font_runtime_points > 255) {
                wmux_test_font_runtime_points = 255;
            }
            if (wmux_test_font_runtime_points < 1) {
                wmux_test_font_runtime_points = 1;
            }
            wmux_test_font_adjusted = true;
            observed_action = 3;
        } else if (strcmp(buffer, "reset_font_size") == 0) {
            wmux_test_font_runtime_points =
                wmux_test_font_configured_runtime_points;
            wmux_test_font_adjusted = false;
            observed_action = 2;
        } else if (strncmp(buffer, "increase_font_size:", 19) == 0) {
            wmux_test_font_runtime_points += strtof(buffer + 19, NULL);
            if (wmux_test_font_runtime_points > 255) {
                wmux_test_font_runtime_points = 255;
            }
            wmux_test_font_adjusted = true;
            observed_action = 0;
        } else if (strncmp(buffer, "decrease_font_size:", 19) == 0) {
            wmux_test_font_runtime_points -= strtof(buffer + 19, NULL);
            if (wmux_test_font_runtime_points < 1) {
                wmux_test_font_runtime_points = 1;
            }
            wmux_test_font_adjusted = true;
            observed_action = 1;
        }
        if (observed_action >= 0
            && wmux_test_font_callback_surface == surface
            && wmux_test_font_callback != NULL) {
            wmux_test_font_callback(
                wmux_test_font_callback_userdata,
                observed_action,
                previous_points,
                wmux_test_font_runtime_points,
                previous_adjusted,
                wmux_test_font_adjusted);
        }
    }
    return true;
}

bool ghostty_surface_set_font_size_action_callback(
    void *surface,
    ghostty_font_size_action_cb callback,
    void *userdata
) {
    if (surface == NULL || callback == NULL) return false;
    wmux_test_font_callback_surface = surface;
    wmux_test_font_callback = callback;
    wmux_test_font_callback_userdata = userdata;
    return true;
}

void ghostty_surface_config_new(void) {}
void ghostty_surface_free(void *surface) {
    const struct timespec timeout = wmux_test_surface_free_timeout();
    pthread_mutex_lock(&wmux_test_surface_free_mutex);
    if (wmux_test_surface_free_should_block
        && surface == wmux_test_surface_free_target) {
        wmux_test_surface_free_started = true;
        pthread_cond_broadcast(&wmux_test_surface_free_condition);
        while (!wmux_test_surface_free_released) {
            const int result = pthread_cond_timedwait_relative_np(
                &wmux_test_surface_free_condition,
                &wmux_test_surface_free_mutex,
                &timeout
            );
            if (result != 0) break;
        }
        wmux_test_surface_free_should_block = false;
        wmux_test_surface_free_target = NULL;
    }
    pthread_mutex_unlock(&wmux_test_surface_free_mutex);

    if (wmux_test_font_callback_surface == surface) {
        wmux_test_font_callback_surface = NULL;
        wmux_test_font_callback = NULL;
        wmux_test_font_callback_userdata = NULL;
    }
    wmux_test_render_callbacks_clear(surface);
}
void ghostty_surface_free_text(void* surface, ghostty_text_s* text) {
    (void)surface;
    (void)text;
}
float ghostty_surface_font_size(void *surface) {
    return surface == wmux_test_font_surface
        ? wmux_test_font_runtime_points
        : 0;
}
bool ghostty_surface_font_size_adjusted(void *surface) {
    return surface == wmux_test_font_surface
        && wmux_test_font_adjusted;
}
uint64_t ghostty_surface_foreground_pid(void *surface) {
    (void)surface;
    return wmux_test_foreground_pid;
}
bool ghostty_surface_grid_metrics(void *surface, void *metrics) {
    (void)surface;
    (void)metrics;
    return false;
}
void ghostty_surface_has_selection(void) {}
bool ghostty_surface_key(void *surface, wmux_test_ghostty_input_key_s key_event) {
    (void)surface;
    // Keep the capture focused on the press. Synthetic named keys may also
    // send a release, which should not erase the fields under test.
    if (key_event.action != 1) {
        return true;
    }
    if (wmux_test_input_event_count_value < 32) {
        wmux_test_input_event_kinds[wmux_test_input_event_count_value++] = 2;
    }
    wmux_test_surface_key_called = true;
    wmux_test_surface_key_mods_value = key_event.mods;
    wmux_test_surface_key_unshifted_codepoint_value = key_event.unshifted_codepoint;
    if (key_event.text != NULL) {
        strncpy(wmux_test_surface_key_text_value, key_event.text, sizeof(wmux_test_surface_key_text_value) - 1);
        wmux_test_surface_key_text_value[sizeof(wmux_test_surface_key_text_value) - 1] = '\0';
    } else {
        wmux_test_surface_key_text_value[0] = '\0';
    }
    return true;
}
void ghostty_surface_mouse_button(void) {}
void ghostty_surface_mouse_pos(void) {}
void ghostty_surface_mouse_scroll(void) {}
bool ghostty_surface_needs_confirm_quit(void *surface) {
    (void)surface;
    return wmux_test_needs_confirm_quit;
}
void ghostty_surface_new(void) {}
bool ghostty_surface_process_exited(void *surface) {
    (void)surface;
    return false;
}
void ghostty_surface_process_output(void *surface, const char *data, uintptr_t len) {
    wmux_test_terminal_modes_apply(surface, data, len);
    pthread_mutex_lock(&wmux_test_process_output_mutex);
    if (wmux_test_process_output_should_block
        && surface == wmux_test_process_output_target) {
        wmux_test_process_output_started = true;
        wmux_test_process_output_called_on_main = pthread_main_np() != 0;
        pthread_cond_broadcast(&wmux_test_process_output_condition);
        while (!wmux_test_process_output_released) {
            const struct timespec timeout = wmux_test_surface_free_timeout();
            const int result = pthread_cond_timedwait_relative_np(
                &wmux_test_process_output_condition,
                &wmux_test_process_output_mutex,
                &timeout
            );
            if (result != 0) break;
        }
        wmux_test_process_output_should_block = false;
        wmux_test_process_output_target = NULL;
    }
    pthread_mutex_unlock(&wmux_test_process_output_mutex);
}
void ghostty_surface_quicklook_font(void) {}
bool ghostty_surface_read_screen_tail_vt(
    void* surface,
    uintptr_t max_rows,
    uintptr_t max_bytes,
    ghostty_text_s* text
) {
    (void)surface;
    (void)max_rows;
    (void)max_bytes;
    static const char value[] = "bounded-tail\r\n";
    if (text == NULL) return false;
    text->text = value;
    text->text_len = sizeof(value) - 1;
    return true;
}
void ghostty_surface_read_text(void) {}
void ghostty_surface_refresh(void) {}
bool ghostty_surface_set_render_presented_callback(
    void *surface,
    void (*callback)(void *, uint64_t),
    void *userdata
) {
    if (surface == NULL || callback == NULL) return false;
    GhosttyRuntimeTestRenderCallbacks* callbacks = wmux_test_render_callbacks_for(surface);
    if (callbacks == NULL || callbacks->presented != NULL) return false;
    callbacks->presented = callback;
    callbacks->presented_userdata = userdata;
    return true;
}
bool ghostty_surface_set_render_failed_callback(
    void *surface,
    void (*callback)(void *, uint64_t, int),
    void *userdata
) {
    if (surface == NULL || callback == NULL) return false;
    GhosttyRuntimeTestRenderCallbacks* callbacks = wmux_test_render_callbacks_for(surface);
    if (callbacks == NULL || callbacks->failed != NULL) return false;
    callbacks->failed = callback;
    callbacks->failed_userdata = userdata;
    return true;
}
bool ghostty_surface_request_render_with_token(void *surface, uint64_t token) {
    GhosttyRuntimeTestRenderCallbacks* callbacks = wmux_test_render_callbacks_for(surface);
    if (callbacks == NULL || callbacks->presented == NULL) return false;
    if (callbacks->has_pending_token) return false;
    callbacks->pending_token = token;
    callbacks->has_pending_token = true;
    return true;
}

bool wmux_test_ghostty_renderer_present(void* surface) {
    GhosttyRuntimeTestRenderCallbacks* callbacks = wmux_test_render_callbacks_for(surface);
    if (callbacks == NULL || callbacks->presented == NULL || !callbacks->has_pending_token) return false;
    const uint64_t token = callbacks->pending_token;
    callbacks->has_pending_token = false;
    callbacks->presented(callbacks->presented_userdata, token);
    return true;
}

bool wmux_test_ghostty_renderer_fail(void* surface, int status) {
    GhosttyRuntimeTestRenderCallbacks* callbacks = wmux_test_render_callbacks_for(surface);
    if (callbacks == NULL || callbacks->failed == NULL || !callbacks->has_pending_token) return false;
    const uint64_t token = callbacks->pending_token;
    callbacks->has_pending_token = false;
    callbacks->failed(callbacks->failed_userdata, token, status);
    return true;
}
void ghostty_surface_render_grid_json(void) {}
void ghostty_surface_render_grid_json_with_theme(void) {}
ghostty_string_s ghostty_surface_render_grid_json_v2(
    void *surface,
    const char *surface_id,
    uintptr_t surface_id_len,
    uint64_t state_seq,
    uintptr_t scrollback_lines,
    bool include_theme,
    bool anchor_active) {
    (void)surface;
    (void)surface_id;
    (void)surface_id_len;
    (void)state_seq;
    (void)scrollback_lines;
    (void)include_theme;
    (void)anchor_active;
    return (ghostty_string_s){0};
}
void ghostty_surface_set_content_scale(void) {}
void ghostty_surface_set_display_id(void) {}
void ghostty_surface_set_focus(void) {}
void ghostty_surface_set_occlusion(void *surface, bool visible) {
    if (surface != wmux_test_renderer_realized_target) return;
    wmux_test_renderer_occlusion_visible = visible;
}
bool ghostty_surface_set_renderer_realized(void *surface, bool realized) {
    if (surface != wmux_test_renderer_realized_target) return true;
    if (!realized) {
        wmux_test_renderer_release_was_occluded = !wmux_test_renderer_occlusion_visible;
    }
    if (wmux_test_renderer_realized_call_count < 16) {
        wmux_test_renderer_realized_calls[wmux_test_renderer_realized_call_count] = realized;
        wmux_test_renderer_realized_call_count++;
    }
    return wmux_test_renderer_realized_result;
}
bool ghostty_surface_rebuild_renderer(void *surface) {
    if (surface != wmux_test_renderer_realized_target) return true;
    wmux_test_renderer_rebuild_call_count++;
    return wmux_test_renderer_realized_result;
}
void ghostty_surface_set_size(void) {}
void ghostty_surface_size(void) {}
void ghostty_surface_text(void) {
    if (wmux_test_input_event_count_value < 32) {
        wmux_test_input_event_kinds[wmux_test_input_event_count_value++] = 1;
    }
}
void ghostty_surface_text_input(void) {
    if (wmux_test_input_event_count_value < 32) {
        wmux_test_input_event_kinds[wmux_test_input_event_count_value++] = 1;
    }
}
void ghostty_surface_update_config(void *surface, void *raw_config) {
    (void)raw_config;
    wmux_test_last_updated_surface = surface;
}
ghostty_string_s ghostty_surface_tty_name(void *surface) {
    (void)surface;
    wmux_test_tty_name_call_count++;
    if (wmux_test_tty_name == NULL) {
        return (ghostty_string_s){0};
    }
    return (ghostty_string_s){.ptr = wmux_test_tty_name, .len = strlen(wmux_test_tty_name), .sentinel = false};
}

uint32_t wmux_test_ghostty_tty_name_call_count(void) {
    return wmux_test_tty_name_call_count;
}

bool wmux_test_ghostty_surface_was_updated(void *surface) {
    return surface == wmux_test_last_updated_surface;
}

void wmux_test_ghostty_font_state_begin(
    void *surface,
    float runtime_points,
    bool adjusted,
    float configured_runtime_points
) {
    wmux_test_font_surface = surface;
    wmux_test_font_runtime_points = runtime_points;
    wmux_test_font_adjusted = adjusted;
    wmux_test_font_configured_runtime_points =
        configured_runtime_points;
    wmux_test_font_binding_succeeds = true;
}

void wmux_test_ghostty_font_state_end(void) {
    wmux_test_font_surface = NULL;
    wmux_test_font_runtime_points = 0;
    wmux_test_font_configured_runtime_points = 0;
    wmux_test_font_adjusted = false;
    wmux_test_font_binding_succeeds = true;
    wmux_test_font_callback_surface = NULL;
    wmux_test_font_callback = NULL;
    wmux_test_font_callback_userdata = NULL;
}

void wmux_test_ghostty_font_binding_result(bool result) {
    wmux_test_font_binding_succeeds = result;
}
