import 'package:flutter/material.dart';

/// Scrolls to the first field (in the given top-to-bottom order) whose
/// [FormFieldState] currently has a validation error — call this right
/// after `formKey.currentState!.validate()` returns false, since
/// `validate()` is what actually runs every field's own validator and
/// updates its `hasError`/`errorText` state; calling this before that
/// would just see stale (or no) error state.
///
/// Fixes a real usability problem: a long form (Add Business, Sign Up,
/// …) that fails validation used to just silently refuse to submit, with
/// no visual cue at all if the invalid field had already scrolled off
/// screen — the only way to notice was scrolling back up by hand to spot
/// which field had turned red. Every required field's own `TextFormField`
/// (or `SelectionField`, which is itself built on `FormField`) needs a
/// `GlobalKey<FormFieldState>` passed in, in the same order it appears
/// on screen, so this can find the first one that's actually invalid.
void scrollToFirstError(List<GlobalKey<FormFieldState<dynamic>>> fieldKeysInOrder) {
  for (final key in fieldKeysInOrder) {
    final state = key.currentState;
    if (state != null && state.hasError) {
      // A short delay lets the error text actually render (and any
      // conditionally-shown fields above it settle) before measuring
      // where to scroll to — without this, ensureVisible can measure
      // against stale layout from just before validate() ran.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = key.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          // Leaves the field a bit below the top of the viewport rather
          // than flush against it (or a keyboard/app bar above it).
          alignment: 0.2,
        );
      });
      return;
    }
  }
}
