import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import RawHtml from "discourse/widgets/raw-html";
import { dateNode } from "discourse/helpers/node";
import { formatUsername } from "discourse/lib/utilities";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export function buildAnchorId(upvotesCommentId) {
  return `upvotes-comment-${upvotesCommentId}`;
}

export default createWidget("upvotes-comment", {
  tagName: "div",
  buildKey: (attrs) => `upvotes-comment-${attrs.id}`,

  buildId(attrs) {
    return buildAnchorId(attrs.id);
  },

  buildClasses(attrs) {
    const result = ["upvotes-comment"];

    if (attrs.deleted) {
      result.push("upvotes-comment-deleted");
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
      return [this.attach("upvotes-comment-editor", attrs)];
    } else {
      const result = [
        h(
          "span.upvotes-comment-cooked",
          new RawHtml({
            html: attrs.cooked,
          })
        ),
        h("span.upvotes-comment-info-separator", "–"),
        h(
          "a.upvotes-comment-info-username",
          {
            attributes: {
              "data-user-card": attrs.username,
            },
          },
          formatUsername(attrs.username)
        ),
        h(
          "span.upvotes-comment-info-created",
          dateNode(new Date(attrs.created_at))
        ),
      ];

      if (
        this.currentUser &&
        (attrs.user_id === this.currentUser.id || this.currentUser.admin)
      ) {
        result.push(this.attach("upvotes-comment-actions", attrs));
      }

      let vote_counter = null;
      if (attrs.upvotes_vote_count) {
        vote_counter = h(
          "span.upvotes-comment-actions-vote-count",
          `${attrs.upvotes_vote_count}`
        );
      }
      return [
        h("div.upvotes-comment-actions-vote", [
          vote_counter,
          this.attach("upvotes-button", {
            direction: "up",
            loading: state.isVoting,
            voted: attrs.user_voted,
          }),
        ]),
        h("div.upvotes-comment-post", result),
      ];
    }
  },

  removeVote() {
    this.state.isVoting = true;

    this.attrs.upvotes_vote_count--;
    this.attrs.user_voted = false;

    return ajax("/upvotes/vote/comment", {
      type: "DELETE",
      data: { comment_id: this.attrs.id },
    })
      .catch((e) => {
        this.attrs.upvotes_vote_count++;
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

    this.attrs.upvotes_vote_count++;
    this.attrs.user_voted = true;

    return ajax("/upvotes/vote/comment", {
      type: "POST",
      data: { comment_id: this.attrs.id },
    })
      .catch((e) => {
        this.attrs.upvotes_vote_count--;
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
