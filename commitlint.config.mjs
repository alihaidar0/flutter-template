export default {
  extends: ["@commitlint/config-conventional"],
  // GitHub names the merge commit of a pull request after its title, and a Dependabot
  // title can exceed 100 characters ("... in the <group> group across 1 directory (#59)").
  // The title is generated and cannot be shortened; the commits inside are still linted.
  ignores: [
    (message) =>
      /^(ci|chore|build)\(deps(-dev)?\): bump [^\n]* \(#\d+\)\s*(\n|$)/.test(message),
  ],
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "perf",
        "test",
        "build",
        "ci",
        "chore",
        "revert",
        "wip",
      ],
    ],
    "subject-case": [
      2,
      "never",
      ["sentence-case", "start-case", "pascal-case", "upper-case"],
    ],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],
  },
};
