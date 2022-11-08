import { createWidget } from "discourse/widgets/widget";
import I18n from "I18n";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";

createWidget("post-voting-comment-editor", {
  tagName: "div",
  buildKey: (attrs) => `post-voting-comment-editor-${attrs.id}`,

  buildClasses(attrs) {
    return [
      "post-voting-comment-editor",
      `post-voting-comment-editor-${attrs.id}`,
    ];
  },

  defaultState(attrs) {
    return { value: attrs.raw, submitDisabled: true };
  },

  html(attrs, state) {
    return [
      this.attach("post-voting-comment-composer", attrs),
      this.attach("button", {
        action: "editComment",
        disabled: state.submitDisabled,
        contents: I18n.t("post_voting.post.post_voting_comment.edit"),
        icon: "pencil-alt",
        className: "btn-primary post-voting-comment-editor-submit",
      }),
      this.attach("link", {
        action: "collapseEditor",
        className: "post-voting-comment-editor-cancel",
        contents: () => I18n.t("post_voting.post.post_voting_comment.cancel"),
      }),
    ];
  },

  updateValue(value) {
    this.state.value = value;
    this.state.submitDisabled =
      value.length < this.siteSettings.min_post_length ||
      value.length > this.siteSettings.qa_comment_max_raw_length;
  },

  keyDown(e) {
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
      this.sendWidgetAction("editComment");
    }
  },

  editComment() {
    this.state.submitDisabled = true;

    return ajax("/post_voting/comments", {
      type: "PUT",
      data: {
        comment_id: this.attrs.id,
        raw: this.state.value,
      },
    })
      .then((response) => {
        this.sendWidgetAction("updateComment", response);
        this.sendWidgetAction("collapseEditor");
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.state.submitDisabled = false;
      });
  },
});
