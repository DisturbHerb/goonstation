import { GameKit } from '..';
import pieces from './pieces';

// Export as gamekit module, use type GameKit
export const kit: GameKit = {
  pieces,
  palettes: [
    {
      name: 'Xiangqi',
      pieces,
    },
  ],
};

export default kit;
