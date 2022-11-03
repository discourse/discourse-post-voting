import { Promise } from "rsvp";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { schedule } from "@ember/runloop";
import I18n from "I18n";

export default createWidget("post-voting-comments-menu", {
  tagName: "div.post-voting-comments-menu",
  buildKey: (attrs) => `post-voting-comments-menu-${attrs.id}`,

  defaultState() {
    return { expanded: false };
  },

  html(attrs, state) {
    const result = [];

    if (state.expanded) {
      result.push(this.attach("post-voting-comments-menu-composer", attrs));
    } else {
      result.push(
        this.attach("link", {
          className: "post-voting-comment-add-link",
          action: this.currentUser ? "expandComposer" : "showLogin",
          actionParam: {
            postId: attrs.id,
            postNumber: attrs.postNumber,
            lastCommentId: attrs.lastCommentId,
          },
          contents: () => I18n.t("post_voting.post.post_voting_comment.add"),
        })
      );
    }

    if (attrs.moreCommentCount > 0) {
      if (!state.expanded) {
        result.push(h("span.post-voting-comments-menu-separator"));
      }

      result.push(
        h("div.post-voting-comments-menu-show-more", [
          this.attach("link", {
            className: "post-voting-comments-menu-show-more-link",
            action: "fetchComments",
            actionParam: {
              post_id: attrs.id,
              last_comment_id: attrs.lastCommentId,
            },
            contents: () =>
              I18n.t("post_voting.post.post_voting_comment.show", {
                count: attrs.moreCommentCount,
              }),
          }),
        ])
      );
    }

    return result;
  },

  expandComposer(data) {
    this.state.expanded = true;

    this.fetchComments({
      post_id: data.postId,
      last_comment_id: data.lastCommentId,
    }).then(() => {
      schedule("afterRender", () => {
        const textArea = document.querySelector(
          `#post_${data.postNumber} .post-voting-comment-composer .post-voting-comment-composer-textarea`
        );

        textArea.focus();
        textArea.select();
      });
    });
  },

  closeComposer() {
    this.state.expanded = false;
  },

  fetchComments(data) {
    if (!data.post_id) {
      return Promise.resolve();
    }

    return ajax("/qa/comments", {
      type: "GET",
      data,
    })
      .then((response) => {
        if (response.comments.length > 0) {
          this.sendWidgetAction("appendComments", response.comments);
        }
      })
      .catch(popupAjaxError);
  },
});
