#!/usr/bin/env python3
from __future__ import annotations

import ast
import pathlib
import re
import sys

DEFAULT_ROOT = pathlib.Path(__file__).resolve().parents[1]

TRANSPORT_LIMITS = {
    "maxTransportFrames": {
        "dart": "maxTransportFrames",
        "android": "MAX_BATCH_SIZE",
        "windows": "kMaxBatchSize",
    },
    "maxTransportPayloadBytes": {
        "dart": "maxTransportPayloadBytes",
        "android": "MAX_PAYLOAD_BYTES",
        "windows": "kMaxPayloadBytes",
    },
    "maxTransportIdentityBytes": {
        "dart": "maxTransportIdentityBytes",
        "android": "MAX_ID_BYTES",
        "windows": "kMaxIdBytes",
    },
}

SOURCE_FILES = {
    "dart": (
        "packages",
        "peerdeal_native_bridges",
        "lib",
        "src",
        "native_bridge_payload_limits.dart",
    ),
    "network": (
        "packages",
        "peerdeal_network",
        "lib",
        "src",
        "models",
        "network_input_limits.dart",
    ),
    "android": (
        "apps",
        "peerdeal_mobile",
        "android",
        "app",
        "src",
        "main",
        "kotlin",
        "com",
        "peerdeal",
        "peerdeal_mobile",
        "NativeTransportHandler.kt",
    ),
    "windows": (
        "apps",
        "peerdeal_desktop",
        "windows",
        "runner",
        "windows_native_transport.cpp",
    ),
    "mobile_app": (
        "apps",
        "peerdeal_mobile",
        "lib",
        "transport",
        "native_transport_session_factory.dart",
    ),
    "desktop_app": (
        "apps",
        "peerdeal_desktop",
        "lib",
        "transport",
        "native_transport_session_factory.dart",
    ),
    "mobile_readiness": (
        "apps",
        "peerdeal_mobile",
        "lib",
        "native_readiness",
        "app_native_readiness_loader.dart",
    ),
    "desktop_readiness": (
        "apps",
        "peerdeal_desktop",
        "lib",
        "native_readiness",
        "app_native_readiness_loader.dart",
    ),
}

APP_PAYLOAD_DEFAULTS = {
    "mobile_app": "NativeBridgePayloadLimits.maxTransportPayloadBytes",
    "desktop_app": "NativeBridgePayloadLimits.maxTransportPayloadBytes",
}

APP_READINESS_PAYLOAD_DEFAULTS = {
    "mobile_readiness": "NativeBridgePayloadLimits.maxTransportPayloadBytes",
    "desktop_readiness": "NativeBridgePayloadLimits.maxTransportPayloadBytes",
}

SEQUENCE_GUARDS = {
    "android": "Int.MAX_VALUE",
    "windows": "std::numeric_limits<int32_t>::max()",
}
SEQUENCE_LIMIT = 0x7FFFFFFF


def _source_path(root: pathlib.Path, platform: str) -> pathlib.Path:
    return root.joinpath(*SOURCE_FILES[platform])


def _declaration_expression(text: str, platform: str, symbol: str) -> str | None:
    escaped_symbol = re.escape(symbol)
    if platform in ("dart", "network"):
        pattern = rf"^\s*static\s+const\s+{escaped_symbol}\s*=\s*([^;]+);"
    elif platform == "android":
        pattern = rf"^\s*private\s+const\s+val\s+{escaped_symbol}\s*=\s*([^\r\n]+)"
    else:
        pattern = rf"^\s*constexpr\s+[^;=]+\s+{escaped_symbol}\s*=\s*([^;]+);"
    match = re.search(pattern, text, flags=re.MULTILINE)
    return match.group(1).strip() if match else None


def _constructor_default_expression(text: str, parameter: str) -> str | None:
    expressions = _constructor_default_expressions(text, parameter)
    return expressions[0] if expressions else None


def _constructor_default_expressions(text: str, parameter: str) -> list[str]:
    pattern = rf"^\s*int\s+{re.escape(parameter)}\s*=\s*([^,]+),"
    return [
        match.group(1).strip()
        for match in re.finditer(pattern, text, flags=re.MULTILINE)
    ]


def _evaluate_integer(expression: str) -> int | None:
    try:
        node = ast.parse(expression, mode="eval").body
    except SyntaxError:
        return None

    def evaluate(value: ast.AST) -> int | None:
        if (
            isinstance(value, ast.Constant)
            and isinstance(value.value, int)
            and not isinstance(value.value, bool)
        ):
            return value.value
        if isinstance(value, ast.UnaryOp) and isinstance(
            value.op, (ast.UAdd, ast.USub)
        ):
            operand = evaluate(value.operand)
            if operand is None:
                return None
            return operand if isinstance(value.op, ast.UAdd) else -operand
        if isinstance(value, ast.BinOp) and isinstance(
            value.op, (ast.Add, ast.Sub, ast.Mult, ast.FloorDiv)
        ):
            left = evaluate(value.left)
            right = evaluate(value.right)
            if left is None or right is None:
                return None
            if isinstance(value.op, ast.Add):
                return left + right
            if isinstance(value.op, ast.Sub):
                return left - right
            if isinstance(value.op, ast.Mult):
                return left * right
            if right == 0:
                return None
            return left // right
        return None

    return evaluate(node)


def check_native_contract_bounds(root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    source_text: dict[str, str] = {}
    for platform in SOURCE_FILES:
        path = _source_path(root, platform)
        relative_path = path.relative_to(root).as_posix()
        try:
            source_text[platform] = path.read_text(encoding="utf-8")
        except FileNotFoundError:
            failures.append(f"{relative_path}: native contract source is missing.")
        except UnicodeDecodeError as error:
            failures.append(f"{relative_path}: invalid utf-8 text: {error}.")

    if failures:
        return failures

    for canonical_name, symbols in TRANSPORT_LIMITS.items():
        dart_expression = _declaration_expression(
            source_text["dart"], "dart", symbols["dart"]
        )
        if dart_expression is None:
            failures.append(
                f"{_source_path(root, 'dart').relative_to(root).as_posix()}: "
                f"missing declaration for {symbols['dart']}."
            )
            continue
        dart_value = _evaluate_integer(dart_expression)
        if dart_value is None:
            failures.append(
                f"{_source_path(root, 'dart').relative_to(root).as_posix()}: "
                f"{symbols['dart']} is not a supported integer expression."
            )
            continue
        for platform in ("android", "windows"):
            symbol = symbols[platform]
            expression = _declaration_expression(
                source_text[platform], platform, symbol
            )
            relative_path = _source_path(root, platform).relative_to(root).as_posix()
            if expression is None:
                failures.append(f"{relative_path}: missing declaration for {symbol}.")
                continue
            value = _evaluate_integer(expression)
            if value is None:
                failures.append(
                    f"{relative_path}: {symbol} is not a supported integer expression."
                )
            elif value != dart_value:
                failures.append(
                    f"{relative_path}: {symbol}={value} does not match "
                    f"Dart {canonical_name}={dart_value}."
                )

    dart_sequence_path = _source_path(root, "dart")
    dart_sequence_expression = _declaration_expression(
        source_text["dart"], "dart", "maxTransportSequence"
    )
    if dart_sequence_expression is None:
        failures.append(
            f"{dart_sequence_path.relative_to(root).as_posix()}: missing "
            "declaration for maxTransportSequence."
        )
    else:
        dart_sequence_value = _evaluate_integer(dart_sequence_expression)
        if dart_sequence_value != SEQUENCE_LIMIT:
            failures.append(
                f"{dart_sequence_path.relative_to(root).as_posix()}: "
                f"maxTransportSequence={dart_sequence_value} does not match "
                f"the signed 32-bit ceiling {SEQUENCE_LIMIT}."
            )

    network_sequence_path = _source_path(root, "network")
    network_sequence_expression = _declaration_expression(
        source_text["network"], "network", "maxTransportSequence"
    )
    if network_sequence_expression is None:
        failures.append(
            f"{network_sequence_path.relative_to(root).as_posix()}: missing "
            "declaration for maxTransportSequence."
        )
    else:
        network_sequence_value = _evaluate_integer(network_sequence_expression)
        if network_sequence_value != SEQUENCE_LIMIT:
            failures.append(
                f"{network_sequence_path.relative_to(root).as_posix()}: "
                f"maxTransportSequence={network_sequence_value} does not match "
                f"the signed 32-bit ceiling {SEQUENCE_LIMIT}."
            )

    for platform, guard in SEQUENCE_GUARDS.items():
        if guard not in source_text[platform]:
            relative_path = _source_path(root, platform).relative_to(root).as_posix()
            failures.append(
                f"{relative_path}: missing signed 32-bit sequence guard {guard}."
            )

    for platform, expected_expression in APP_PAYLOAD_DEFAULTS.items():
        relative_path = _source_path(root, platform).relative_to(root).as_posix()
        expression = _constructor_default_expression(
            source_text[platform], "maxPayloadBytes"
        )
        if expression is None:
            failures.append(
                f"{relative_path}: missing native transport default for "
                "maxPayloadBytes."
            )
        elif expression != expected_expression:
            failures.append(
                f"{relative_path}: maxPayloadBytes default {expression!r} must "
                f"reference {expected_expression}."
            )

    for platform, expected_expression in APP_READINESS_PAYLOAD_DEFAULTS.items():
        relative_path = _source_path(root, platform).relative_to(root).as_posix()
        expressions = _constructor_default_expressions(
            source_text[platform], "nativeTransportMaxPayloadBytes"
        )
        if not expressions:
            failures.append(
                f"{relative_path}: missing native readiness default for "
                "nativeTransportMaxPayloadBytes."
            )
        else:
            for expression in expressions:
                if expression != expected_expression:
                    failures.append(
                        f"{relative_path}: nativeTransportMaxPayloadBytes default "
                        f"{expression!r} must reference {expected_expression}."
                    )

    return failures


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    root = pathlib.Path(args[0]).resolve() if args else DEFAULT_ROOT
    failures = check_native_contract_bounds(root)

    if failures:
        print("Native contract bound check failed:")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print("Native contract bound check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
