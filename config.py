CAIRO_MANIFEST_PATH = "/home/kali/Downloads/cairo-2.0.0/Cargo.toml"

CORE_CONTRACTS = [
    {"contract_name": "main", "cairo_version": 0},
    {"contract_name": "proxy", "cairo_version": 0},
    {"contract_name": "nft", "cairo_version": 0},
]

# points 0 to auxiliary challenge smart contracts
CHALLENGE_CONTRACTS = [
    {"contract_name": "challenge1", "cairo_version": 2, "challenge_number": 1, "points": 50},
    {"contract_name": "challenge2", "cairo_version": 2, "challenge_number": 2, "points": 100},
    {"contract_name": "challenge3", "cairo_version": 2, "challenge_number": 3, "points": 200},
    {"contract_name": "challenge4", "cairo_version": 0, "challenge_number": 4, "points": 200},
    {"contract_name": "challenge5", "cairo_version": 0, "challenge_number": 5, "points": 300},
    {"contract_name": "challenge6", "cairo_version": 0, "challenge_number": 6, "points": 300},
    {"contract_name": "challenge7", "cairo_version": 0, "challenge_number": 7, "points": 500},
    {"contract_name": "challenge7_erc20", "cairo_version": 0, "challenge_number": 7, "points": 0},
    {"contract_name": "challenge8", "cairo_version": 0, "challenge_number": 8, "points": 1500},
    {"contract_name": "challenge8_dex", "cairo_version": 0, "challenge_number": 8, "points": 0},
    {"contract_name": "challenge8_erc20", "cairo_version": 0, "challenge_number": 8, "points": 0},
    {"contract_name": "challenge8_erc223", "cairo_version": 0, "challenge_number": 8, "points": 0},
    {"contract_name": "challenge9", "cairo_version": 0, "challenge_number": 9, "points": 500},
    {"contract_name": "challenge10", "cairo_version": 2, "challenge_number": 10, "points": 700},
    {"contract_name": "challenge11", "cairo_version": 0, "challenge_number": 11, "points": 300},
]