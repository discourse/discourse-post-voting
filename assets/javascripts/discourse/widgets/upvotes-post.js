import { createWidget } from "discourse/widgets/widget";
import { castVote, removeVote, whoVoted } from "../lib/upvotes-utilities";
import { h } from "virtual-dom";
import { smallUserAtts } from "discourse/widgets/actions-summary";
import { iconNode } from "discourse-common/lib/icon-library";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default createWidget("upvotes-post", {
  tagName: "div.upvotes-post",
  buildKey: (attrs) => `upvotes-post-${attrs.post.id}`,

  sendShowLogin() {
    const appRoute = this.register.lookup("route:application");
    appRoute.send("showLogin");
  },

  defaultState() {
    return {
      voters: [],
      loading: false,
    };
  },

  html(attrs, state) {
    const contents = [
      this.attach("upvotes-button", {
        direction: "up",
        loading: state.loading,
        voted: attrs.post.upvotes_user_voted_direction === "up",
      }),
    ];

    if (attrs.post.upvotes_has_votes) {
      contents.push(
        this.attach("button", {
          action: "toggleWhoVoted",
          contents: `${attrs.post.upvotes_vote_count}`,
          className: "upvotes-post-toggle-voters btn btn-flat",
        })
      );

      if (state.voters.length > 0) {
        const upVoters = [];
        const downVoters = [];

        state.voters.forEach((voter) => {
          if (voter.direction === "up") {
            upVoters.push(voter);
          } else {
            downVoters.push(voter);
          }
        });

        const upvotesPostVotersList = [];
        const upVotersList = this._postVotersList("up", upVoters);

        if (upVotersList) {
          upvotesPostVotersList.push(upVotersList);
        }

        const downVotersList = this._postVotersList("down", downVoters);

        if (downVotersList) {
          upvotesPostVotersList.push(downVotersList);
        }

        if (upvotesPostVotersList.length > 0) {
          contents.push(h(".upvotes-post-list", upvotesPostVotersList));
        }

        const countDiff = attrs.post.upvotes_vote_count - state.voters.length;

        if (countDiff > 0) {
          contents.push(this.attach("span", "and ${countDiff} more users..."));
        }
      }
    } else {
      contents.push(
        h(
          "span.upvotes-post-toggle-voters",
          `${attrs.post.upvotes_vote_count || 0}`
        )
      );
    }

    contents.push(
      this.attach("upvotes-button", {
        direction: "down",
        loading: state.loading,
        voted: attrs.post.upvotes_user_voted_direction === "down",
      })
    );

    return contents;
  },

  _postVotersList(direction, voters) {
    if (voters.length > 0) {
      const icon = direction === "up" ? "caret-up" : "caret-down";

      return h("div.upvotes-post-list-voters-wrapper", [
        h("span.upvotes-post-list-icon", iconNode(icon)),
        h("span.upvotes-post-list-count", `${voters.length}`),
        this.attach("small-user-list", {
          users: voters,
          listClassName: "upvotes-post-list-voters",
        }),
      ]);
    }
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
        state.voters = result.voters.map((voter) => {
          const userAttrs = smallUserAtts(voter);
          userAttrs.direction = voter.direction;
          return userAttrs;
        });

        this.scheduleRerender();
      }
    });
  },

  removeVote(direction) {
    const post = this.attrs.post;
    const countChange = direction === "up" ? -1 : 1;

    post.setProperties({
      upvotes_user_voted_direction: null,
      upvotes_vote_count: post.upvotes_vote_count + countChange,
    });

    const voteCount = post.upvotes_vote_count;

    this.state.loading = true;

    return removeVote({ post_id: post.id })
      .catch((error) => {
        post.setProperties({
          upvotes_user_voted_direction: direction,
          upvotes_vote_count: voteCount - countChange,
        });

        this.scheduleRerender();

        popupAjaxError(error);
      })
      .finally(() => (this.state.loading = false));
  },

  vote(direction) {
    if (!this.currentUser) {
      return this.sendShowLogin();
    }

    const post = this.attrs.post;

    let vote = {
      post_id: post.id,
      direction,
    };

    const isUpVote = direction === "up";
    let countChange;

    if (post.upvotes_user_voted_direction) {
      countChange = isUpVote ? 2 : -2;
    } else {
      countChange = isUpVote ? 1 : -1;
    }

    this.attrs.post.setProperties({
      upvotes_user_voted_direction: direction,
      upvotes_vote_count: post.upvotes_vote_count + countChange,
    });

    const voteCount = post.upvotes_vote_count;

    this.state.loading = true;

    return castVote(vote)
      .catch((error) => {
        post.setProperties({
          upvotes_user_voted_direction: null,
          upvotes_vote_count: voteCount - countChange,
        });

        this.scheduleRerender();

        popupAjaxError(error);
      })
      .finally(() => (this.state.loading = false));
  },
});
