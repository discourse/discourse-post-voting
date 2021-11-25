import { createWidget } from "discourse/widgets/widget";
import { castVote, whoVoted } from "../lib/qa-utilities";
import { h } from "virtual-dom";
import { smallUserAtts } from "discourse/widgets/actions-summary";
import { iconNode } from "discourse-common/lib/icon-library";

export default createWidget("qa-post", {
  tagName: "div.qa-post",
  buildKey: (attrs) => `qa-post-${attrs.post.id}`,

  sendShowLogin() {
    const appRoute = this.register.lookup("route:application");
    appRoute.send("showLogin");
  },

  defaultState() {
    return {
      voters: [],
    };
  },

  html(attrs, state) {
    const contents = [this.attach("qa-button", { direction: "up" })];
    const voteCount = attrs.post.qa_vote_count;

    if (voteCount > 0) {
      contents.push(
        this.attach("button", {
          action: "toggleWhoVoted",
          contents: attrs.count,
          className: "qa-post-toggle-voters",
        })
      );

      if (state.voters.length > 0) {
        contents.push(
          h(".qa-post-list", [
            h("span.qa-post-list-icon", iconNode("angle-up")),
            h("span.qa-post-list-count", `${voteCount}`),
            this.attach("small-user-list", {
              users: state.voters,
              listClassName: "qa-post-list-voters",
            }),
          ])
        );

        const countDiff = voteCount - state.voters.length;

        if (countDiff > 0) {
          contents.push(this.attach("span", "and ${countDiff} more users..."));
        }
      }
    }

    return contents;
  },

  toggleWhoVoted() {
    const state = this.state;

    if (state.voters.length > 0) {
      state.voters = [];
    } else {
      return this.getWhoVoted();
    }
  },

  clickOutside() {
    if (this.state.voters.length > 0) {
      this.state.voters = [];
      this.scheduleRerender();
    }
  },

  getWhoVoted() {
    const { attrs, state } = this;

    whoVoted({ post_id: attrs.post.id }).then((result) => {
      if (result.voters) {
        state.voters = result.voters.map(smallUserAtts);
        this.scheduleRerender();
      }
    });
  },

  vote(direction) {
    const user = this.currentUser;

    if (!user) {
      return this.sendShowLogin();
    }

    const post = this.attrs.post;

    let vote = {
      user_id: user.id,
      post_id: post.id,
      direction,
    };

    castVote({ vote });
  },
});
