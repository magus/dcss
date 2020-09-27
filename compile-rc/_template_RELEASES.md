# FAQ

### What's new?

Sometimes you want to know what has changed between your current version
of the RC and the another version, usually the latest version.
Follow the instructions below to easily see the differences!

1. Copy your **Version** string

    ![Example screenshot highlighting magus.rc version string](https://raw.githubusercontent.com/magus/dcss/master/static/version-string-example.dac80c.png)

    _Example_
    ```
    {{ExampleVersion}}
    ```

1. Find the row with your **Version** string in the [Releases](#Releases) table below

1. Copy the **SHA** column from the row containing your **Version**

    > [What's a SHA?](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/github-glossary#commit-id)

1. Using the URL below, replace **`<SHA>`** with the **SHA** you found above

    ```
    https://github.com/magus/dcss/compare/<SHA>...{{ExampleSHA}}
    ```
    _Example_: `https://github.com/magus/dcss/compare/{{ExampleSHA}}...{{GIT_HEAD_SHA}}`

1. Paste the new URL into your browser and discover all the changes since you last copied the RC, Enjoy! 😄


# Releases
| Version  | SHA |
| ------------- | ------------- |
{{AllReleases}}

