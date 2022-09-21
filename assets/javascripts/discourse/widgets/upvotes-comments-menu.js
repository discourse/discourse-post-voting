import { Promise } from "rsvp";
import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { schedule } from "@ember/runloop";
import I18n from "I18n";

export default createWidget("upvotes-comments-menu", {
  tagName: "div.upvotes-comments-menu",
  buildKey: (attrs) => `upvotes-comments-menu-${attrs.id}`,

  defaultState() {
    return { expanded: false };
  },

  html(attrs, state) {
    const result = [];

    if (state.expanded) {
      result.push(this.attach("upvotes-comments-menu-composer", attrs));
    } else {
      result.push(
        this.attach("link", {
          className: "upvotes-comment-add-link",
          action: this.currentUser ? "expandComposer" : "showLogin",
          actionParam: {
            postId: attrs.id,
            postNumber: attrs.postNumber,
            lastCommentId: attrs.lastCommentId,
          },
          contents: () => I18n.t("upvotes.post.upvotes_comment.add"),
        })
      );
    }

    if (attrs.moreCommentCount > 0) {
      if (!state.expanded) {
        result.push(h("span.upvotes-comments-menu-seperator"));
      }

      result.push(
        h("div.upvotes-comments-menu-show-more", [
          this.attach("link", {
            className: "upvotes-comments-menu-show-more-link",
            action: "fetchComments",
            actionParam: {
              post_id: attrs.id,
              last_comment_id: attrs.lastCommentId,
            },
            contents: () =>
              I18n.t("upvotes.post.upvotes_comment.show", {
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
          `#post_${data.postNumber} .upvotes-comment-composer .upvotes-comment-composer-textarea`
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

    return ajax("/upvotes/comments", {
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
