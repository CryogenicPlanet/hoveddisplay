import { ActionPanel, Detail, List, Action, Icon, Color, showToast, Toast, environment } from "@raycast/api";
import { exec } from "child_process";
import { useExec } from "@raycast/utils";

import { z } from "zod";

const userPath = environment.supportPath.split("/Library")[0];

const cmdPath = `${userPath}/.local/bin/set-main-display`;

export const schema = z.array(
  z.object({
    id: z.number(),
    isMain: z.boolean(),
    type: z.string(),
    rect: z.object({
      y: z.number(),
      x: z.number(),
      width: z.number(),
      height: z.number(),
    }),
    uuid: z.string(),
  })
);

function execPromise(command: string) {
  return new Promise(function (resolve, reject) {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout.trim());
    });
  });
}

export const useCheckCLI = () => {
  const { isLoading, error, data, revalidate } = useExec(cmdPath, ["list"]);

  return { loading: isLoading, hasClI: error ? false : data !== undefined ? true : false, revalidate };
};

export default function SetMainDisplayWrapper() {
  const { loading, hasClI, revalidate } = useCheckCLI();

  if (loading) {
    return <List isLoading={true} />;
  }
  if (hasClI) {
    return <SetMainDisplay />;
  }

  return (
    <Detail
      markdown={`
  # You do not have our cli installed

  You cannot use this extension without the accompanying CLI tool. 

  Go to [here](https:/github.com/cryogenicplanet/set-main-display) for more info.
  `}
      actions={
        <ActionPanel>
          <Action.OpenInBrowser url="https:/github.com/cryogenicplanet/set-main-display" />
          <Action title="Refresh" onAction={() => revalidate()} />
        </ActionPanel>
      }
    />
  );
}

function SetMainDisplay() {
  const { isLoading, data, revalidate } = useExec(cmdPath, ["json"]);

  const ChangeMainDisplay = async (uuid: string) => {
    const toast = await showToast({ style: Toast.Style.Animated, title: "Updating Main Display" });
    try {
      await execPromise(`${cmdPath} change ${uuid}`);
      revalidate();

      // yay, the API call worked!
      toast.style = Toast.Style.Success;
      toast.title = "Updated Main Display!";
    } catch (err) {
      // oh, the API call didn't work :(
      // the data will automatically be rolled back to its previous value
      toast.style = Toast.Style.Failure;
      toast.title = "Could not update main display";
      // @ts-expect-error
      toast.message = err.message;
    }
  };

  const unsafe_displays = data ? JSON.parse(data) : [];
  const displays = schema.parse(unsafe_displays);

  return (
    <List isLoading={isLoading}>
      {displays.map((display) => (
        <List.Item
          key={display.id}
          icon={Icon.Monitor}
          title={display.type}
          subtitle={`${display.rect.width}x${display.rect.height}`}
          accessories={[
            { icon: display.isMain ? { source: Icon.Checkmark, tintColor: Color.Green } : null },
            { text: display.isMain ? "Main" : null },
          ]}
          actions={
            <ActionPanel>
              <Action title="Set as Main Display" onAction={() => ChangeMainDisplay(display.uuid)} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
