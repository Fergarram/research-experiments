# Part 1 - Game
## Introduction
This is one of those projects which are born after a burst of excitement but you end up not 
finishing it, to the #uncomfortable point were it isn’t good enough to publish but it is 
good enough to talk about it.

Do we support emojis? 🧠

Some inlined `code` here and a test here: '`' wtf `\``. // Backslashing is manually processed

So, in this series I will share with you how I retake this project and finish it to the MVP 
point in ~~two weekends~~!

Adding some code here:

```bash

# This is some sample bash code
echo "Let's try some _markdown_ ~~crazy~~ [shit](shit.com)"

```

This below should make the block fail
```````
bla bla "```" The middle tick thinks that it's a SNIP_MIDDLE
which probably means that this will fail as well: ### haha
```

## What the project is about
I bought a _banana phone_ after watching some video about this (I don’t remember exactly what 
video it was). The fact that I could create apps for a feature phone using web technologies 
blew my mind — I remember being a kid and creating what we now call “feature phones” using 
small and thin wood rectangles that (for some strange reason) were laying around in my 
house. I would make different designs using tape, rubber bands, nails and color markers.

#### Just another test 4

##### Just another test 5

###### Just another test 6

Anyways, I bought the thing and went on to enable development mode and got a Hello World 
app running.

A few months past by and suddenly decided I wanted to do something with it. I though of 
remaking [How would we handle things like this where they wrap?](https://fergarram.itch.io/
amateur-archaeology-iii) for a game jam some years ago using Game Maker. This was the perfect 
idea, the game was simple enough so I started on working on it.

## Defining the MVP
As a starting point it should have the same functionalities as the original game with some 
variations and additions:

* Infinite diggin' (done before this devlog started)
* Intro screen
* Dialogs (UI)
* Treasures - with different rewards
* Time, score and game states
* Foes - Fire and Scorpions
* Randomized hue (can change) 

### Game Rules
1. Game objective is to reach the score goal before time runs out.
2. If you pass the score goal you get extra time for the next level.

## Day 1
I’ll start by taking the intro image from the original game and adapting it to the 
resolution of the Banana Phone (240 x 320px). I use [Aseprite](https://www.aseprite.org/) 
for manipulating pixels and [Sketch](https://www.sketch.com/) for… level design? I like to 
use Sketch for moving the assets around and prototyping ideas.