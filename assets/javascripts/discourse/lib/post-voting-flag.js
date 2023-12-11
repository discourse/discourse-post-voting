import Flag from "discourse/lib/flag-targets/flag";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class PostVotingFlag extends Flag {
  title() {
    return "flagging.title";
  }

  customSubmitLabel() {
    return "flagging.notify_action";
  }

  submitLabel() {
    return "flagging.action";
  }

  flagCreatedEvent() {
    return "post:flag-created";
  }

  flagsAvailable(flagModal) {
    debugger;
    let flagsAvailable = flagModal.site.flagTypes;

    flagsAvailable = flagsAvailable.filter((flag) => {
      return flagModal.args.model.flagModel.availableFlags.includes(
        flag.name_key
      );
    });

    const notifyUserIndex = flagsAvailable.indexOf(
      flagsAvailable.filterBy("name_key", "notify_user")[0]
    );

    if (notifyUserIndex !== -1) {
      const notifyUser = flagsAvailable[notifyUserIndex];
      flagsAvailable.splice(notifyUserIndex, 1);
      flagsAvailable.splice(0, 0, notifyUser);
    }

    return flagsAvailable;
  }

  async create(flagModal, opts) {
    flagModal.args.closeModal();
    debugger;

    return ajax("/post_voting/comments/flag", {
      method: "PUT",
      data: {
        comment_id: flagModal.args.model.flagModel.id,
        flag_type_id: flagModal.selected.id,
        message: opts.message,
        is_warning: opts.isWarning,
        take_action: opts.takeAction,
        queue_for_review: opts.queue_for_review,
      },
    }).catch((error) => popupAjaxError(error));
  }
}