import { hbs } from "ember-cli-htmlbars";
import { registerWidgetShim } from "discourse/widgets/render-glimmer";

registerWidgetShim(
  "post-voting-button",
  "div.post-voting-button-shim",
  hbs`<PostVotingButton
    @direction={{@data.direction}}
    @loading={{@data.loading}}
    @voted={{@data.voted}}
    @removeVote={{@data.removeVote}}
    @vote={{@data.vote}}
    @disabled={{@data.disabled}}
  />`
);
