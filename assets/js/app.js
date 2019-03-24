// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";
import tachyons from "../css/tachyons.min.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

// Putting sockets here to test for now, then will move to sockets.js
import { Socket } from "phoenix";

const socketParams = (window.userToken == "") ? {} : { token: window.userToken };
const socket = new Socket("/socket", {
  params: socketParams,
});

socket.connect();

// Elm
import { Elm } from "../elm/src/Main.elm";

const elmContainer = document.getElementById("elm-container");
const justSmashBricks = document.getElementById("just-smash-bricks");
const platformer = document.getElementById("platformer")
const siam = document.getElementById("siam");

if (elmContainer) {
  Elm.Main.init({ node: elmContainer });
}

if (justSmashBricks) {
  Elm.Games.JustSmashBricks.init({ node: justSmashBricks });
}

if (siam) {
  // Elm.Games.Siam.init({ node: siam });
  const app = Elm.Games.Siam.init({ node: siam });

  const channel = socket.channel("siam:game", {});

  channel.join()
    .receive("ok", resp => { console.log("Joined Siam successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  channel.on("get_state", payload => {
    console.log(`Receiving ${payload.player} from Phoenix using the receiveState port.`);
    app.ports.receiveState.send({
      turn: payload.player,
    })
  });

  app.ports.requestState.subscribe(function () {
    console.log(`Requesting state.`);
    // Push to Phoenix channel

    channel.push("request_state", {});
  });
}

if (platformer) {
  const app = Elm.Games.Platformer.init({
    node: platformer,
    flags: { token: window.userToken }
  });

  const channel = socket.channel("score:platformer", {});

  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  channel.on("broadcast_score", payload => {
    console.log(`Receiving ${payload.player_score} score data from Phoenix using the receivingScoreFromPhoenix port.`);
    app.ports.receiveScoreFromPhoenix.send({
      game_id: payload.game_id || 0,
      player_id: payload.player_id || 0,
      player_score: payload.player_score || 0,
    });
  });

  app.ports.broadcastScore.subscribe(function (scoreData) {
    console.log(`Broadcasting ${scoreData} score data from Elm using the broadcastScore port.`);
    // Push to Phoenix channel
    channel.push("broadcast_score", { player_score: scoreData });
  });

  app.ports.saveScore.subscribe(function (scoreData) {
    console.log(`Saving ${scoreData} score data from Elm using the saveScore port`);
    channel.push("save_score", { player_score: scoreData });
  })
}