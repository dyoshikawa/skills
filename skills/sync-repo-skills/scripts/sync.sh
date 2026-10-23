#!/usr/bin/env bash
# Mirror the skills of a repository under repos/ into this workspace as
# `<repo>-<name>`: repos/<repo>/.rulesync/skills/<name> -> .rulesync/skills/<repo>-<name>.
#
#   sync.sh <repo> [repos-root]
#
# <repo> is the directory name under repos/. [repos-root] overrides the parent
# directory of the repositories (default: <workspace>/repos), e.g. when running
# from a git worktree that has no repos/ checkout of its own.
#
# What it does, per source skill:
#   - copies the whole directory (references/, LICENSE.txt, ...) afresh;
#   - sets the frontmatter `name` to `<repo>-<name>` and adds a `# synced-from:`
#     YAML comment after it so later runs can tell synced copies from native skills;
#   - in SKILL.md only, rewrites backticked references to any skill of the
#     source set (`goal-pr` -> `rulesync-goal-pr`) so the imported set refers
#     to itself rather than to same-named workspace skills. A skill's own name
#     in its own body is left alone unless the line mentions "skill": such
#     self-mentions are usually a same-named command (e.g. `playwright-cli`).
# Synced copies whose source skill no longer exists are deleted; a directory
# without the marker is never deleted. The prefix is applied literally, so a
# source skill that already starts with `<repo>-` gets it twice; those are
# listed in the report.
#
# The source repository is untrusted input: a skill name must consist only of
# letters, digits, '.', '_' and '-' and must not start with '.'; the source and
# destination skills directories must resolve to exactly
# <repos-root>/<repo>/.rulesync/skills and <workspace>/.rulesync/skills (no
# symlinked path component); and no source skill directory or anything inside
# it may be a symlink. So nothing outside .rulesync/skills/<repo>-<name> is
# ever written or deleted, and nothing outside the source tree is read.
#
# The report on stdout lists added / updated / unchanged / removed skills, the
# rewritten and skipped lines for review, double-prefixed names, and whether an
# unprefixed workspace skill of the same name exists and is identical.
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "usage: $0 <repo> [repos-root]" >&2
  exit 2
fi
repo=$1
# valid_name <name>: a single, plain path component (the perl rewrite quotes
# each name, so '.' in a name matches only a literal dot).
valid_name() {
  case "$1" in
    "" | .* | *[!A-Za-z0-9._-]*) return 1 ;;
  esac
}
if ! valid_name "$repo"; then
  echo "error: invalid repository name: $repo" >&2
  exit 2
fi
root=$(git rev-parse --show-toplevel)
repos_root=${2:-$root/repos}
src=$repos_root/$repo/.rulesync/skills
dst=$root/.rulesync/skills
prefix="$repo-"
marker="# synced-from: repos/$repo/.rulesync/skills/"

if [ ! -d "$src" ]; then
  echo "error: source skills directory not found: $src" >&2
  exit 1
fi
if [ ! -d "$dst" ]; then
  echo "error: destination skills directory not found: $dst" >&2
  exit 1
fi
# Refuse a symlink anywhere on the way to either skills directory.
if [ "$(realpath -e "$src")" != "$(realpath -e "$repos_root")/$repo/.rulesync/skills" ] ||
  [ -L "$repos_root/$repo" ]; then
  echo "error: refusing to use a source skills directory reached through a symlink: $src" >&2
  exit 1
fi
if [ "$(realpath -e "$dst")" != "$(realpath -e "$root")/.rulesync/skills" ]; then
  echo "error: refusing to use a destination skills directory reached through a symlink: $dst" >&2
  exit 1
fi
# NUL-delimited so a name with a newline in it cannot split into several names.
names=()
while IFS= read -r -d '' p; do
  n=${p##*/}
  if [ -L "$p" ]; then
    echo "error: refusing to sync a symlinked entry: $p" >&2
    exit 1
  fi
  [ -d "$p" ] || continue
  if ! valid_name "$n"; then
    printf 'error: invalid skill directory name under %s: %q\n' "$src" "$n" >&2
    exit 1
  fi
  names+=("$n")
done < <(find "$src" -mindepth 1 -maxdepth 1 -print0)
if [ ${#names[@]} -eq 0 ]; then
  echo "error: no skills under $src" >&2
  exit 1
fi
mapfile -t names < <(printf '%s\n' "${names[@]}" | sort)
for n in "${names[@]}"; do
  if [ ! -f "$src/$n/SKILL.md" ]; then
    echo "error: $src/$n has no SKILL.md" >&2
    exit 1
  fi
  if [ -n "$(find "$src/$n" -type l -print -quit)" ]; then
    echo "error: $src/$n contains a symlink; refusing to sync it" >&2
    exit 1
  fi
done
alt=$(IFS='|'; echo "${names[*]}")

# synced_from <SKILL.md> <name>: print the synced-from marker line only where
# the script itself puts it — in the frontmatter, right after `name: <name>` —
# so a marker-like line elsewhere in a source skill cannot fake one.
synced_from() {
  awk -v want="name: $2" '
    /^---[[:space:]]*$/ { if (++fm == 2) exit; next }
    fm == 1 { if (prev == want && index($0, "# synced-from: ") == 1) { print; exit } prev = $0 }
  ' "$1"
}

added=() updated=() unchanged=() removed=() double_prefixed=() overwrote_unmarked=()
rewritten=() skipped=()

# 1. Prune synced copies whose source is gone. Only directories carrying the
#    marker qualify; anything else under the prefix may be a native skill.
for d in "$dst/$prefix"*; do
  # Never follow a symlink: rm -rf on it (or on "link/") could reach outside $dst.
  [ -L "$d" ] && continue
  [ -d "$d" ] || continue
  n=$(basename "$d")
  f="$d/SKILL.md"
  [ -f "$f" ] || continue
  line=$(synced_from "$f" "$n")
  case "$line" in "$marker"*) ;; *) continue ;; esac
  from=${line#"$marker"}
  if [ ! -d "$src/$from" ] || [ "$n" != "$prefix$from" ]; then
    rm -rf "$d"
    removed+=("$n")
  fi
done

# 2. Copy and rewrite each source skill into a staging directory, then compare
#    with what is already there to classify the change and move it into place.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for n in "${names[@]}"; do
  target="$prefix$n"
  case "$n" in "$prefix"*) double_prefixed+=("$target") ;; esac
  stage="$tmp/$target"
  cp -R "$src/$n" "$stage"
  log="$tmp/$target.log"
  NAME="$n" PREFIX="$prefix" ALT="$alt" MARKER="$marker$n" LOG="$log" perl -i -pe '
    BEGIN { $fm = 0; $done_name = 0; my $a = join "|", map { quotemeta } split /\|/, $ENV{ALT}; $alt = qr/`($a)`/; }
    $line = $.;
    if (/^---\s*$/) { $fm++; }
    $in_fm = ($fm == 1);
    if ($in_fm && !$done_name && /^name:\s*\Q$ENV{NAME}\E\s*$/) {
      $_ = "name: $ENV{PREFIX}$ENV{NAME}\n$ENV{MARKER}\n";
      $done_name = 1;
      next;
    }
    my $orig = $_;
    if ($in_fm || /skill/i) {
      s/$alt/`$ENV{PREFIX}$1`/g;
    } else {
      # body line without "skill": leave self-mentions (likely a command) alone
      s/$alt/$1 eq $ENV{NAME} ? "`$1`" : "`$ENV{PREFIX}$1`"/ge;
      if ($orig =~ /`\Q$ENV{NAME}\E`/) {
        open(my $l, ">>", $ENV{LOG}); print $l "skipped $line: $orig"; close $l;
      }
    }
    if ($_ ne $orig) {
      open(my $l, ">>", $ENV{LOG}); print $l "rewrote $line: $_"; close $l;
    }
  ' "$stage/SKILL.md"
  if [ "$(synced_from "$stage/SKILL.md" "$target")" != "$marker$n" ]; then
    echo "error: $src/$n/SKILL.md has no 'name: $n' line in its frontmatter" >&2
    exit 1
  fi
  if [ -f "$log" ]; then
    while IFS= read -r l; do
      case "$l" in
        rewrote*) rewritten+=("$target/SKILL.md:${l#rewrote }") ;;
        skipped*) skipped+=("$target/SKILL.md:${l#skipped }") ;;
      esac
    done < "$log"
  fi

  if [ -L "$dst/$target" ]; then
    echo "error: refusing to replace a symlink: $dst/$target" >&2
    exit 1
  fi
  if [ -d "$dst/$target" ]; then
    if diff -rq "$dst/$target" "$stage" >/dev/null; then
      unchanged+=("$target")
      continue
    fi
    case "$(synced_from "$dst/$target/SKILL.md" "$target" 2>/dev/null)" in
      "$marker"*) ;;
      *) overwrote_unmarked+=("$target") ;;
    esac
    rm -rf "${dst:?}/$target"
    updated+=("$target")
  else
    added+=("$target")
  fi
  mv "$stage" "$dst/$target"
done

# 3. Report.
list() { # <title> <items...>
  local title=$1; shift
  echo "$title ($#):"
  for i in "$@"; do echo "  $i"; done
}
echo "Synced repos/$repo/.rulesync/skills -> .rulesync/skills/$prefix* (${#names[@]} skills)"
list "added" "${added[@]}"
list "updated" "${updated[@]}"
list "unchanged" "${unchanged[@]}"
list "removed (source gone)" "${removed[@]}"
if [ ${#overwrote_unmarked[@]} -gt 0 ]; then
  list "overwrote directories that had no synced-from marker (check they were not native skills)" "${overwrote_unmarked[@]}"
fi
if [ ${#double_prefixed[@]} -gt 0 ]; then
  list "double-prefixed (source name already started with '$prefix')" "${double_prefixed[@]}"
fi
echo "same-name workspace skills (unprefixed):"
for n in "${names[@]}"; do
  if [ -d "$dst/$n" ] && [ ! -L "$dst/$n" ]; then
    if diff -rq "$src/$n" "$dst/$n" >/dev/null; then echo "  $n: identical"; else echo "  $n: differs"; fi
  fi
done
echo "rewritten lines (review: a token that is a command, path or product rather than the skill must be reverted by hand):"
for l in "${rewritten[@]}"; do printf '  %s\n' "$l"; done
echo "skipped self-mentions (body lines without \"skill\"; review: revert to the prefixed name if they do mean the skill):"
for l in "${skipped[@]}"; do printf '  %s\n' "$l"; done
