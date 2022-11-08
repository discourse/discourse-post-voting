import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import RawHtml from "discourse/widgets/raw-html";
import { dateNode } from "discourse/helpers/node";
import { formatUsername } from "discourse/lib/utilities";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export function buildAnchorId(commentId) {
  return `post-voting-comment-${commentId}`;
}

export default createWidget("post-voting-comment", {
  tagName: "div",
  buildKey: (attrs) => `post-voting-comment-${attrs.id}`,

  buildId(attrs) {
    return buildAnchorId(attrs.id);
  },

  buildClasses(attrs) {
    const result = ["post-voting-comment"];

    if (attrs.deleted) {
      result.push("post-voting-comment-deleted");
    }

    return result;
  },

  sendShowLogin() {
    const appRoute = this.register.lookup("route:application");
    appRoute.send("showLogin");
  },

  defaultState() {
    return { isEditing: false, isVoting: false };
  },

  html(attrs, state) {
    if (state.isEditing) {
      return [this.attach("post-voting-comment-editor", attrs)];
    } else {
      const result = [
        h(
          "span.post-voting-comment-cooked",
          new RawHtml({
            html: attrs.cooked,
          })
        ),
        h("span.post-voting-comment-info-separator", "–"),
        h(
          "a.post-voting-comment-info-username",
          {
            attributes: {
              "data-user-card": attrs.username,
            },
          },
          formatUsername(attrs.username)
        ),
        h(
          "span.post-voting-comment-info-created",
          dateNode(new Date(attrs.created_at))
        ),
      ];

      if (
        this.currentUser &&
        (attrs.user_id === this.currentUser.id || this.currentUser.admin)
      ) {
        result.push(this.attach("post-voting-comment-actions", attrs));
      }

      let vote_counter = null;
      if (attrs.post_voting_vote_count) {
        vote_counter = h(
          "span.post-voting-comment-actions-vote-count",
          `${attrs.post_voting_vote_count}`
        );
      }
      return [
        h("div.post-voting-comment-actions-vote", [
          vote_counter,
          this.attach("post-voting-button", {
            direction: "up",
            loading: state.isVoting,
            voted: attrs.user_voted,
          }),
        ]),
        h("div.post-voting-comment-post", result),
      ];
    }
  },

  removeVote() {
    this.state.isVoting = true;

    this.attrs.post_voting_vote_count--;
    this.attrs.user_voted = false;

    return ajax("/post_voting/vote/comment", {
      type: "DELETE",
      data: { comment_id: this.attrs.id },
    })
      .catch((e) => {
        this.attrs.post_voting_vote_count++;
        this.attrs.user_voted = true;
        popupAjaxError(e);
      })
      .finally(() => {
        this.state.isVoting = false;
      });
  },

  vote(direction) {
    if (!this.currentUser) {
      return this.sendShowLogin();
    }

    if (direction !== "up") {
      return;
    }

    this.state.isVoting = true;

    this.attrs.post_voting_vote_count++;
    this.attrs.user_voted = true;

    return ajax("/post_voting/vote/comment", {
      type: "POST",
      data: { comment_id: this.attrs.id },
    })
      .catch((e) => {
        this.attrs.post_voting_vote_count--;
        this.attrs.user_voted = false;
        popupAjaxError(e);
      })
      .finally(() => {
        this.state.isVoting = false;
      });
  },

  expandEditor() {
    this.state.isEditing = true;
  },

  collapseEditor() {
    this.state.isEditing = false;
  },
});
