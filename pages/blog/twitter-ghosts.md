---
title: "The Haunted Twitter Account"
date: 2019-01-08
tweet: TODO "@ThinkAboutConf #thinkabout19"
author_twitter: "@hldrbm"
author: Jakob
draft: true

---

On Monday the 7th of January it happend. Over night we had more than 300
additional Twitter followers. Sound cool right?

Unfortunately, it is not. We were not praised by sudden fame. All of those 300
new followers where ghost followers: fake accounts that only exist to increase
the reach of another account.

## The Short Version

Our account is haunted. Since the 7th of January we had 300 more followers and
since then we get a few new ghost followers every other minute. Just when I
checked this morning there where again over 300 more followers then last
evening.

Meet [Ghostbuster](https://github.com/hrx-events/ghostbuster), the friendly
commandline app to automatically delete all those nasty twitter ghost
followers.

### The Issue

While reach through a lot of followers is usually a desireable thing on
Twitter, having a lot of ghost followers is not. This can have several severe
drawbacks:

1. Credibility: your account can be perceived as one of those shady twitter
citicens who pay money to gain extra followers
2. Ranking: Twitter may detect this behaviour and reduce your visibility
3. Ban: Twitter may even decide to ban you account because the suspect a fraud
scheme

To me personally, the weirdest thing about this situation is that we never
payed anyone to give us hundreds of fake followers. It kind of just popped into
existance out of the blue. If anybody knows how such a thing can happen, please
give me a tweet ([@thinkaboutconf](https://twitter.com/thinkaboutconf)) or a
mail ([kontakt@think-about.io](mailto:kontakt@think-about.io)).

### The Solution

I wrote a simple piece of code, that utilizes the twitter API to detect ghost
followers and automatically bans them. If you ban a follower, they are removed
from your list of followers and may never follow or contact you again. Quite
drastic, but very efficient against automated fake accounts.

The detection is so far quite simple. It deletes all followers that are either:

1. With less than 10 followers
2. or have at most one post of their own

From the analysis of our ghost followers I could deduce this rule. All those
fake accounts have barely any followers and always just one "welcome" post or
no post at all.

Head over to Github and download
[Ghostbuster](https://github.com/hrx-events/ghostbuster). In order to use it,
you have to enable API access on twitter and create a twitter app. Both are
quire easy to do in a few steps which I will outline here.
