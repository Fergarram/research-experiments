TODO:

[ ] Encode neighboring rules into a string or set of strings
[ ] Ability to change the OpenCL program in run-time

NOTAS @beto: Todo lo de abajo de aqui esta outdated.

--------------------------------------------------------------------------------

Improvements:

- History Access and Export
- Hot-reload OpenCL C program

--------------------------------------------------------------------------------

How do I condense multiple cells into a single one?

--------------------------------------------------------------------------------

I'm having a realization again. My approach has been the wrong approach. I need to take more layers and have space into close consideration. Consider the following example:

```
# We could have a title like this

#We could have a title like this

  # We could have a title like this

 #   We could have a title like this
```

The second sample line above is the trickiest one for sure, but the others would in theory make it possible to parse correctly without the need of a prediction system.

I have been trying to use neighboring rules on raw data when the correct approach would be to take all characters including nulls or spaces into their corresponding tokens.

An approach based on words is closer to reality.

--------------------------------------------------------------------------------

A problem I'm encountering is that I myself don't have strict exact rules for Markdown syntax. I'm kinda making the rules on the go, I'm improvising. So that might say that there are no strict rules at all, never(?). 

What if instead of being sure about something being something it's rather a "could be"? For example, instead of saying "I'm for sure a HEAD_SINGLE" say, "I could be a HEAD_SINGLE" and let the final decision be made by the top layer in the hierarchy.

--------------------------------------------------------------------------------

There are always going to be multiple ways to solve categorization problems like this one. I think I'm getting overwhelmed by the ones I can think of.

There's always going to be new ways of determining if something is correct.

Each cell can ask questions to other cells.
This questions are (usually?) referential, meaning that the answer is a reference that can be answer by eventually getting a piece of data which is evidence that a cell may have.

Although, what if each cell is allowed to ask about a direction?
For example, "is there someone to your left that X?"

I don't know the technical implications but this basically allows long distance // connectivity between cells.

--------------------------------------------------------------------------------

I think that the next layer above `characters` is the `word` layer. This is where instead of looking at a single '#' character we have a "heading X start". This is where individual priority character cells transcend into a word space. This would allow for things statements like "if a link chain '](' is next to 'https' or 'www', then it's most likely this is a link block".

[ Characters -> Words/Tokens -> Blocks ] -> Document

Priority Character Types
'#', '-', '~', '[', ']', '>', '`', '(', ')', ' ', '!', '*', '_', '0..9', '.'

Tokens
- Heading Start
- Paragraph Chunk
- Underline Start, Underline End
...

In order to identify which heading size it is, memory would need to be used. Whenever there are a number of seen {{Heading Start}} tokens in a row, such a fact would activate a memory indicator that this is, for example, an <H4> block.

Thoughts for being a '#':
1. If I'm a '#' and I'm at the beginning, I could be a {{Heading Start}}.
2. If my right neighbor is a space, I am a heading 1 start.
3. If my right neighbor is a '#', I could be any {{Heading Start}} except 
   a heading 1 start.
4. If my neighbors think they are part of a heading, then it reasurres
   me that I'm a heading as well.

What are all the necessary conditions for a character of a certain type to be a part of a heading 1?

MUSTS for {{Heading Start}}: ( 33.33% each )
1. Be a '#'
2. Left neighbor is '#', null or (user mistake) space
3. Right neighbor is '#' or space or (user mistake) alphanumeric

Is there any way to negate those 3 rules above? Some fact that would cancel out the reassurance of itself? I think yes, but not always. The thing is, I might need to be in the token space to be able to cancel something out, but I'm guessing not always?

COMPLETION for {{Heading Start}}:
1. Right token is <Paragraph Chunk>

NEGATIONS for X:
1. The MUST no. 2 user mistake cannot be true if there is any left token other than {{Heading Start}}.
2. The MUST no. 3 user mistake cannot be true if there is any left token other than {{Heading Start}}.

REINFORCEMENTS for {{Heading Start}}:
1. Horizontal neighbors think they're part of a heading or {{Heading Start}}

REINFORCEMENTS for <HEADING>:
1. Empty lines above or below the heading line
2. Usually short line

It seems that I might be needing multiple layers and that memory will be used more often than not.

NOTES:

* How much does it increase in activation with each rule?
* Could it be that the amount of rules and their conclusions define 
  the amount of activation it will have?
* How do rules cancel each other out?
* Can there be an algorithm that defines the amount of activation a set of 
  rules would result in?

Maybe one other thing that comes out of this research is a way of creating models in an easier fashion for existing AI technologies and techniques?
