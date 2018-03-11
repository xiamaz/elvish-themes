# DO NOT EDIT THIS FILE DIRECTLY
# This is a file generated from a literate programing source file located at
# https://github.com/zzamboni/elvish-themes/blob/master/chain.org.
# You should make any changes there and regenerate it from Emacs org-mode using C-c C-v t

prompt-segments-defaults = [ su dir git-branch git-combined arrow ]
rprompt-segments-defaults = [ ]

use re

use github.com/muesli/elvish-libs/git

prompt-segments = $prompt-segments-defaults
rprompt-segments = $rprompt-segments-defaults

glyph = [
  &git-branch=    "⎇"
  &git-dirty=     "✎ "
  &git-ahead=     "⬆"
  &git-behind=    "⬇"
  &git-staged=    "✔"
  &git-untracked= "+"
  &git-deleted=   "-"
  &su=            "⚡"
  &chain=         "─"
  &arrow=         ">"
]

segment-style = [
  &git-branch=    blue
  &git-dirty=     yellow
  &git-ahead=     "38;5;52"
  &git-behind=    "38;5;52"
  &git-staged=    "38;5;22"
  &git-untracked= "38;5;52"
  &git-deleted=   "38;5;52"
  &su=            yellow
  &chain=         default
  &arrow=         green
  &dir=           cyan
  &timestamp=     gray
]

prompt-pwd-dir-length = 1

timestamp-format = "%R"

root-id = 0

bold-prompt = $false

fn -colorized [what color]{
  if (!=s $color default) {
    if $bold-prompt {
      color = $color";bold"
    }
    edit:styled $what $color
  } else {
    put $what
  }
}

fn -colorized-glyph [segment-name @extra-text]{
  -colorized $glyph[$segment-name](joins "" $@extra-text) $segment-style[$segment-name]
}

fn prompt-segment [segment-or-style @texts]{
  style = $segment-or-style
  if (has-key $segment-style $segment-or-style) {
    style = $segment-style[$segment-or-style]
  }
  if (has-key $glyph $segment-or-style) {
    texts = [ $glyph[$segment-or-style] $@texts ]
  }
  text = "["(joins ' ' $texts)"]"
  -colorized $text $style
}

segment = [&]

last-status = [&]

fn -any-staged {
  count [(each [k]{
        explode $last-status[$k]
  } [staged-modified staged-deleted staged-added renamed copied])]
}

fn -parse-git {
  last-status = (git:status)
  last-status[any-staged] = (-any-staged)
}

segment[git-branch] = {
  branch = $last-status[branch-name]
  if (not-eq $branch "") {
    if (eq $branch '(detached)') {
      branch = $last-status[branch-oid][0:7]
    }
    prompt-segment git-branch $branch
  }
}

fn -show-git-indicator [segment]{
  status-name = [
    &git-dirty=     local-modified
    &git-ahead=     rev-ahead
    &git-behind=    rev-behind
    &git-staged=    any-staged
    &git-untracked= untracked
    &git-deleted=   local-deleted
  ]
  value = $last-status[$status-name[$segment]]
  # The indicator must show if the element is >0 or a non-empty list
  if (eq (kind-of $value) list) {
    not-eq $value []
  } else {
    > $value 0
  }
}

fn -git-prompt-segment [segment]{
  if (-show-git-indicator $segment) {
    prompt-segment $segment
  }
}

-git-indicator-segments = [untracked deleted dirty staged ahead behind]

each [ind]{
  segment[git-$ind] = { -git-prompt-segment git-$ind }
} $-git-indicator-segments

segment[git-combined] = {
  indicators = [(each [ind]{
        if (-show-git-indicator git-$ind) { -colorized-glyph git-$ind }
  } $-git-indicator-segments)]
  if (> (count $indicators) 0) {
    put '[' $@indicators ']'
  }
}

fn -prompt-pwd {
  tmp = (tilde-abbr $pwd)
  if (== $prompt-pwd-dir-length 0) {
    put $tmp
  } else {
    re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $tmp
  }
}

segment[dir] = {
  prompt-segment dir (-prompt-pwd)
}

segment[su] = {
  uid = (id -u)
  if (eq $uid $root-id) {
    prompt-segment su
  }
}

segment[timestamp] = {
  prompt-segment timestamp (date +$timestamp-format)
}

segment[arrow] = {
  -colorized-glyph arrow " "
}

fn -interpret-segment [seg]{
  k = (kind-of $seg)
  if (eq $k 'fn') {
    # If it's a lambda, run it
    $seg
  } elif (eq $k 'string') {
    if (has-key $segment $seg) {
      # If it's the name of a built-in segment, run its function
      $segment[$seg]
    } else {
      # If it's any other string, return it as-is
      put $seg
    }
  } elif (eq $k 'styled') {
    # If it's an edit:styled, return it as-is
    put $seg
  }
}

fn -build-chain [segments]{
  if (eq $segments []) {
    return
  }
  first = $true
  output = ""
  -parse-git
  for seg $segments {
    time = (-time { output = [(-interpret-segment $seg)] })
    if (> (count $output) 0) {
      if (not $first) {
        -colorized-glyph chain
      }
      put $@output
      first = $false
    }
  }
}

fn prompt {
  if (not-eq $prompt-segments []) {
    put (-build-chain $prompt-segments)
  }
}

fn rprompt {
  if (not-eq $rprompt-segments []) {
    put (-build-chain $rprompt-segments)
  }
}

fn init {
  edit:prompt = $prompt~
  edit:rprompt = $rprompt~
}

init
