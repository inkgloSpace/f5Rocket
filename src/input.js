const KEY_ACTIONS = Object.freeze({
  ArrowLeft: "left",
  KeyA: "left",
  ArrowRight: "right",
  KeyD: "right",
  ArrowUp: "up",
  KeyW: "up",
  ArrowDown: "down",
  KeyS: "down",
  Space: "fire",
  Enter: "restart",
  KeyP: "pause",
  F3: "debug",
  Digit1: "stress1",
  Digit2: "stress2",
  Digit3: "stress3",
  Digit4: "stress4",
});

function shouldPreventDefault(action) {
  return action === "left" || action === "right" || action === "up" || action === "down" || action === "fire";
}

export function createKeyboardInput(target) {
  const down = Object.create(null);
  const pressed = Object.create(null);

  function onKeyDown(event) {
    const action = KEY_ACTIONS[event.code];

    if (!action) {
      return;
    }

    if (shouldPreventDefault(action) || action === "debug") {
      event.preventDefault();
    }

    if (!down[action] && !event.repeat) {
      pressed[action] = true;
    }

    down[action] = true;
  }

  function onKeyUp(event) {
    const action = KEY_ACTIONS[event.code];

    if (!action) {
      return;
    }

    if (shouldPreventDefault(action) || action === "debug") {
      event.preventDefault();
    }

    down[action] = false;
  }

  function onBlur() {
    const actions = Object.keys(down);

    for (let index = 0; index < actions.length; index += 1) {
      down[actions[index]] = false;
    }
  }

  target.addEventListener("keydown", onKeyDown);
  target.addEventListener("keyup", onKeyUp);
  target.addEventListener("blur", onBlur);

  return {
    isDown(action) {
      return down[action] === true;
    },

    consume(action) {
      if (pressed[action]) {
        pressed[action] = false;
        return true;
      }
      return false;
    },

    destroy() {
      target.removeEventListener("keydown", onKeyDown);
      target.removeEventListener("keyup", onKeyUp);
      target.removeEventListener("blur", onBlur);
    },
  };
}
