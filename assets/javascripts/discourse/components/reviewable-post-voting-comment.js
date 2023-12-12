import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
import ChatChannel from "discourse/plugins/chat/discourse/models/chat-channel";

export default class ReviewableChatMessage extends Component {
  @service store;
  @service chatChannelsManager;

  @cached
  get chatChannel() {
    return ChatChannel.create(this.args.reviewable.chat_channel);
  }
}
