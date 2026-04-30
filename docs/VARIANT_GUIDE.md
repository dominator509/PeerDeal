# PeerDeal Variant Guide

## Locked order
1. Hold'em
2. Omaha
3. PLO
4. future variants later

## Rules
- keep variant rules inside peerdeal_variants
- keep mode policy out of variant code
- keep evaluator logic behind a stable interface
- do not leak Hold'em assumptions into universal core
