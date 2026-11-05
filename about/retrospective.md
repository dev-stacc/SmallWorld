# What I'd do differently

This doubles as a CV piece. Built solo while teaching myself the stack.

- Module structure from day one. I started by copying patterns I saw in other repos. That worked at one or two hosts but got hard to navigate at five. With 3+ hosts planned, I'd go straight to the current `modules/{system,home}/{common,host-specific}` split instead of refactoring my way into it.
- Authentik before the apps. I deployed Jellyfin and Navidrome first and had to refactor both substantially once Authentik landed and they needed SSO wiring. Next time the auth layer goes up first, and every app is wired into it from the start.
- Branches, PRs, and code review. I worked mostly on `main` because this started as a personal project; the cost is a noisy log and no review trail. What I got wrong was treating it as a discipline problem - intending to branch was never the issue, nothing enforced it. The repo is public and Flux reconciles straight from `main`, so a bad commit is deployed and world-readable before I can reconsider it. CI now runs on every PR, which lets `main` require a passing check instead of relying on me to remember.
- More research before coding. Solo work on my own hardware made me unafraid to break things, which is great for momentum and bad for measuring twice.
