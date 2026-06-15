from __future__ import annotations

from build_release_candidate_assets import build_player_atlas


def main() -> None:
	build_player_atlas()
	print("Generated full-body release-candidate R-17 player atlas")


if __name__ == "__main__":
    main()
