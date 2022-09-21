import { createWidget } from "discourse/widgets/widget";
import I18n from "I18n";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";

createWidget("upvotes-comment-editor", {
  tagName: "div",
  buildKey: (attrs) => `upvotes-comment-editor-${attrs.id}`,

  buildClasses(attrs) {
    return ["upvotes-comment-editor", `upvotes-comment-editor-${attrs.id}`];
  },

  defaultState(attrs) {
    return { value: attrs.raw, submitDisabled: true };
  },

  html(attrs, state) {
    return [
      this.attach("upvotes-comment-composer", attrs),
      this.attach("button", {
        action: "editComment",
        disabled: state.submitDisabled,
        contents: I18n.t("upvotes.post.upvotes_comment.edit"),
        icon: "pencil-alt",
        className: "btn-primary upvotes-comment-editor-submit",
      }),
      this.attach("link", {
        action: "collapseEditor",
        className: "upvotes-comment-editor-cancel",
        contents: () => I18n.t("upvotes.post.upvotes_comment.cancel"),
      }),
    ];
  },

  updateValue(value) {
    this.state.value = value;
    this.state.submitDisabled =
      value.length < this.siteSettings.min_post_length ||
      value.length > this.siteSettings.upvotes_comment_max_raw_length;
  },

  keyDown(e) {
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
      this.sendWidgetAction("editComment");
    }
  },

  editComment() {
    this.state.submitDisabled = true;

    return ajax("/upvotes/comments", {
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
