import { useBackend, useLocalState } from '../../../../backend';
import { Box, Button } from '../../../../components';
import { useActions, useStates } from '../../utils/config';
import { BoardgameData } from '../../utils/types';

export const TitleBar = (props, context) => {
  const { act, data } = useBackend<BoardgameData>(context);
  const { width, height } = data.boardInfo;
  const { isFlipped, toggleFlip, helpModalOpen, isHelpModalOpen, isModalOpen } = useStates(context);
  const { boardClear } = useActions(act);

  const [clearConfirm, setClearConfirm] = useLocalState(context, 'clearConfirm', false);

  const openModalStyles: CSSProperties = {
    'opacity': isModalOpen ? 0.5 : 1,
    'pointer-events': isModalOpen ? 'none' : 'auto',
  };

  return (
    <Box className="boardgame__titlebar">
      <Button
        style={openModalStyles}
        color={isHelpModalOpen ? 'orange' : 'default'}
        icon="question"
        onClick={() => helpModalOpen()}>
        Help
      </Button>
      <Button style={openModalStyles} color={isFlipped ? 'orange' : 'default'} icon="repeat" onClick={toggleFlip}>
        Flip board
      </Button>
      <Button
        style={openModalStyles}
        onMouseOut={() => setClearConfirm(false)}
        color={clearConfirm ? 'orange' : 'default'}
        icon="trash"
        onClick={() => {
          if (clearConfirm) {
            boardClear({ width, height });
            setClearConfirm(false);
          } else {
            setClearConfirm(true);
          }
        }}>
        {clearConfirm ? 'Confirm' : 'Clear board'}
      </Button>
      <SetupButton />
    </Box>
  );
};

const SetupButton = (props, context) => {
  const { openModal, closeModal, isModalOpen } = useStates(context);

  const bgColor = isModalOpen ? '#f2711c' : 'default';
  const textColor = isModalOpen ? 'white' : 'white';
  const zIndex = isModalOpen ? 100 : 0;

  return (
    <Button
      icon={'cog'}
      onClick={() => {
        if (isModalOpen) {
          closeModal();
        } else {
          openModal();
        }
      }}
      style={{
        'background-color': bgColor,
        'color': textColor,
      }}>
      {isModalOpen ? 'Close' : 'Setup'}
    </Button>
  );
};

/* SetupButton.defaultHooks = {
  shouldComponentUpdate: () => false,
};*/

export default TitleBar;
