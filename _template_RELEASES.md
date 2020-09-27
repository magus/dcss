# FAQ
> How do I use this file?

1. Find your version string in this file

    _Example_
    ```
    {{ExampleVersion}}
    ```

2. Copy the alphanumeric [commit ID (SHA)](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/github-glossary#commit-id)

3. Use the SHA in the URL below to discover all the changes since you last copied the RC!

    ```
    https://github.com/magus/dcss/compare/<SHA>...{{ExampleSHA}}
    ```
    _Example_: `https://github.com/magus/dcss/compare/{{ExampleSHA}}...{{GIT_HEAD_SHA}}`

# Releases
{{AllReleases}}
