/* ios_bridge.c — iOS entry point and stdio/exit shims for unmodified Dungeon.
 *
 * This file is the ONLY C code added on top of the upstream Dungeon sources.
 * The upstream tree at the repo root is byte-identical to devshane/zork; the
 * package's cSettings rewrite `main` → `dungeon_main` via -Dmain=dungeon_main,
 * and the symbol shims below redirect supp.c's `exit(0)` and any printf-family
 * calls in the legacy code without touching their source.
 *
 * Two-level namespace:
 *   Darwin resolves system-dylib calls (libSystem's own internal printf/exit)
 *   against libSystem at link time. Our shadowing definitions ONLY affect calls
 *   whose .o files are linked into our binary — i.e., the legacy game code.
 */

#include <setjmp.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* setjmp target used by the exit() shim to bail back to run_dungeon(). */
static jmp_buf dungeon_exit_jump;
volatile int dungeon_exited = 0;

static int game_out_fd = -1;
static int game_in_fd  = -1;

void configure_dungeon_io(int out_write_fd, int in_read_fd)
{
    game_out_fd = out_write_fd;
    game_in_fd  = in_read_fd;
}

/* ── stdio overrides ───────────────────────────────────────────────────── */

int putchar(int c)
{
    if (game_out_fd >= 0) {
        unsigned char ch = (unsigned char)c;
        write(game_out_fd, &ch, 1);
    }
    return c;
}

int puts(const char *s)
{
    if (game_out_fd >= 0 && s) {
        write(game_out_fd, s, strlen(s));
        write(game_out_fd, "\n", 1);
    }
    return 0;
}

int printf(const char *fmt, ...)
{
    if (game_out_fd < 0) return 0;
    va_list args;
    va_start(args, fmt);
    char buf[4096];
    int n = vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    if (n > 0) write(game_out_fd, buf, (size_t)n);
    return n;
}

/* ── exit() shim ───────────────────────────────────────────────────────────
 * The legacy supp.c's exit_() ends with `exit(0)`. We catch that here and
 * longjmp back to run_dungeon() instead of terminating the host process.
 * Signature & noreturn attribute match libc's so callers compiled against
 * <stdlib.h> see a compatible declaration. */

__attribute__((noreturn))
void exit(int code)
{
    (void)code;
    fflush(stdout);
    fflush(stderr);
    dungeon_exited = 1;
    longjmp(dungeon_exit_jump, 1);
}

/* ── game entry point ──────────────────────────────────────────────────── */

/* Forward decl of the legacy entry point. The C target's cSettings define
 * `main` → `dungeon_main`, so dmain.c's `void main(...)` is renamed at
 * compile time and resolves to the symbol below. */
extern void dungeon_main(int argc, char **argv);

void run_dungeon(void)
{
    dungeon_exited = 0;

    /* Redirect STDIN_FILENO so getchar/scanf in the legacy code read from our
     * input pipe. Safe in a foreground iOS app — no system framework reads fd 0. */
    if (game_in_fd >= 0) {
        dup2(game_in_fd, STDIN_FILENO);
    }

    if (setjmp(dungeon_exit_jump) == 0) {
        dungeon_main(0, NULL);
    }
    /* Arrived here either after longjmp from exit() or normal return. */
}
