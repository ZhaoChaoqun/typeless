import { Composition } from "remotion";
import { TypelessPromo } from "./TypelessPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="TypelessPromo"
        component={TypelessPromo}
        durationInFrames={540} // 18秒 @ 30fps
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
