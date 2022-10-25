# hoveddisplay

A way to progmatically change main display on macos. Swift CLI and Raycast extension both included

## Demo

https://user-images.githubusercontent.com/10355479/197719985-d93373a7-0eb5-49da-af6d-a0db8ab0b2fa.mp4


## Install

### CLI

```bash
brew tap cryogenicplanet/hoveddisplay
brew install hoveddisplay
```

### Raycast

The CLI is **required** for raycast extension to work.

For right now, just clone this repo and import it as an extension in raycast. I will publish this to the raycast extension repo at some point

## Usage

### CLI

```bash
hoveddisplay list # Returns a list of all displays
hoveddisplay json # Returns this list as JSON

hoveddisplay change <UUID> # Sets the main display to the one specified
hoveddisplay change 37D8832A-2D66-02CA-B9F7-8F30A301B230
```

### Raycast

The demo above shows the raycast usage. The extension is pretty simple, it just runs the CLI with the selected display as an argument.

## Acknowledgment

This was heavily insipired by https://github.com/jakehilborn/displayplacer and was a starting guide for building this, the main difference is that this automatically sets your origins so you can just choose which is your main display.
