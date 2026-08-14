"""Helpers for Datadog AI Guard deny responses."""

try:
    from ddtrace.appsec.ai_guard._api_client import AIGuardAbortError
except ImportError:
    AIGuardAbortError = None


def is_ai_guard_abort(exc: BaseException) -> bool:
    if AIGuardAbortError is not None and isinstance(exc, AIGuardAbortError):
        return True
    return type(exc).__name__ == "AIGuardAbortError"


def reraise_if_ai_guard(exc: BaseException) -> None:
    """Re-raise AI Guard deny errors so API routes can return a structured block response."""
    if is_ai_guard_abort(exc):
        raise exc


def _display_reason(exc: BaseException) -> str:
    reason = getattr(exc, "reason", None) or str(exc)
    if reason.startswith("Rule matches: "):
        reason = reason[len("Rule matches: ") :]
    tags = getattr(exc, "tags", None) or []
    if not reason and tags:
        reason = tags[0]
    return reason or "policy violation"


def ai_guard_block_payload(exc: BaseException, *, endpoint: str) -> dict:
    tags = list(getattr(exc, "tags", None) or [])
    reason = _display_reason(exc)
    action = getattr(exc, "action", "DENY")

    payload = {
        "blocked": True,
        "blocker": "ai_guard",
        "action": action,
        "reason": reason,
        "tags": tags,
        "message": f"Datadog AI Guard blocked this request ({reason}).",
        "answer": "",
    }

    if endpoint == "ctf":
        payload.update(
            {
                "challenge_completed": False,
                "evidence_url": None,
                "evaluation": {
                    "success": False,
                    "confidence": 1.0,
                    "reasoning": f"Blocked by Datadog AI Guard: {reason}",
                    "key_phrases": tags or [reason],
                },
            }
        )

    return payload
