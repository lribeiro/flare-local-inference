# Build targets for Flare. These mirror the documented setup in
# docs/model-preparation.md ("Environment setup"); that guide stays authoritative
# for dependency policy, FlashInfer pins, and GPU/toolchain requirements.

UV ?= uv
CARGO ?= cargo

# Recipe shells search the `make deps` installer locations (~/.local/bin for
# uv, ~/.cargo/bin for rustup) even when the current shell has not picked them
# up, so `make` works in the same shell that ran `make deps`.
export PATH := $(PATH):$(HOME)/.local/bin:$(HOME)/.cargo/bin

.PHONY: all deps sync build extension clean

all: sync build extension

# System build dependencies (Ubuntu), plus uv and a Rust toolchain when they are
# not already on PATH. Explicit target because apt-get needs sudo. Rust comes
# from rustup (flare requires Rust 1.88+; Ubuntu's apt cargo is older).
deps:
	sudo apt-get install -y build-essential cmake ninja-build pkg-config \
		protobuf-compiler libssl-dev python3-dev liburing-dev curl
	@if ! command -v $(UV) >/dev/null 2>&1; then \
		echo "uv not found; installing it with the standalone installer"; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	fi
	@if ! command -v $(CARGO) >/dev/null 2>&1; then \
		echo "cargo not found; installing Rust with rustup"; \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal; \
	fi

# Preparation environment from uv.lock, including the prepare and test extras.
sync:
	@command -v $(UV) >/dev/null 2>&1 || \
		{ echo "uv not found; run 'make deps' to install it"; exit 1; }
	$(UV) sync --locked --extra prepare --extra test

# Native CLI: flare/target/release/flare
build:
	@command -v $(CARGO) >/dev/null 2>&1 || \
		{ echo "cargo not found; run 'make deps' to install Rust"; exit 1; }
	$(CARGO) build --release --manifest-path flare/Cargo.toml

# Rebuild the installed flare_heliopause extension after changing
# heliopause/ or Helios code it uses.
extension:
	@command -v $(UV) >/dev/null 2>&1 || \
		{ echo "uv not found; run 'make deps' to install it"; exit 1; }
	$(UV) pip install --python .venv/bin/python --no-deps ./heliopause

clean:
	$(CARGO) clean --manifest-path flare/Cargo.toml
