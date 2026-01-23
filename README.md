# Aidan's user-level Claude Configuration

This contains the general rules in [CLAUDE.md](CLAUDE.md), and skills in the [skills](skills) directory.

Other files are stored in ~/.claude but they are not configuration.  

## CLAUDE.md

I've tried to keep this incredibly short. It should be quite language-agnostic. Specifics can go into other files/skills/whatever.

I've asked Claude and it assures me that

 - It knows the content of Stephen Pinker's *The Sense of Style* (hooray for stolen IP!), so I don't need to spell out the style from that book
 - Giving examples of good/bad patterns is unnecessary e.g. for comments. I notice that LLM-generated rules files often include that. But it seems redundant. Let's try not having it

I will come back and see how well this terse version is working out but it appeals in a less-is-more style.

Also in this file, I refer to a convention of having an ARCHITECTURE.md file. I've found it very useful in the past to start working on a project by asking Claude to read the whole project and write that file. Then, it can use that file to save time searching around for the same things over and over. 

## Skills

I've really just trying these. They work well in basic tests, but how well will they work in day-to-day use? Time will tell here, too. 

Some thoughts I've had along the way are:

 - Time spent optimising the skill is probably worthwhile. The skills here could be done by the raw agent, but we're helping by describing the smoothest, shortest path to the goal. And it can go from 10 tool calls to 1 or 2. 
 - The salesforce-org-symbols skill uses scripts to provide a level of indirection. This is for safety: the skill can only access the current default org; and for simplicity: the scripts is easier for the LLM that the details of using the CLI and it can reformat the output
 - Skills allow you to pre-approve some tool calls. This could be very dangerous, but is convenient if the approvals are for read-only operations (e.g. ls, grep) or for specially written scripts that are not harmful
 - It seems that Claude doesn't think to call a skill while using another skill
 - Explaining the expected skill use in CLAUDE.md seems to help, especially using the keyword "before" because Claude doesn't always use skills for things that it already knows how to do.