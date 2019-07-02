---
DGP: 3
Title: Voting REST API 
Status: Active
Author: Devender Yadav (devender-yadav)
Created: 2019-07-03
---

# Voting REST API

Vote endpoints returns html response. For example, https://app.dock.io/vote/0xf5c57613806020a478e68df7b1ea186ef9206087

If we have an endpoint thats returns JSON, something like:

    {
      "contract": "0xf5c57613806020a478e68df7b1ea186ef9206087",
      "docks_voted": 599388,
      "days_left": 6,
      "approve": 100,
      "reject": 0
    }

 and another endpoint to give list of ids of all active proposals.
 
That can be used in **Telegram bot** to show active proposals to generate more traffic on proposals. Because it's easier to see proposals and discuss on them in telegram group itself.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
