/**
 * @file
 * @copyright 2023
 * @author DisturbHerb (https://github.com/disturbherb)
 * @license ISC
 */

import { classes } from 'common/react';
import { useBackend, useLocalState } from '../../backend';
import { Button, Divider, Dropdown, Image, Input, Section, Stack } from '../../components';
import { Window } from '../../layouts';
import { ClothingBoothData, ClothingBoothItemInformationProps, ClothingBoothSlotKeys } from './type';

import { capitalize } from '../common/stringUtils';

// Credit to @TobleroneSwordfish for this sort function.
// basic sorting function for numbers and strings
const AZCompare = function (a, b, sortBy) {
  if (!isNaN(a[sortBy]) && !isNaN(b[sortBy])) {
    return a[sortBy] - b[sortBy];
  }
  return ('' + a[sortBy]).localeCompare(b[sortBy]);
};

export const ClothingBooth = (_, context) => {
  const { data } = useBackend<ClothingBoothData>(context);

  return (
    <Window title={data.name} width={400} height={500}>
      <Window.Content>
        <Stack fill vertical>
          {/* Topmost section, containing the cash balance. */}
          <Stack.Item>
            <Section fill>
              <Stack fluid align="center" justify="space-between">
                <Stack.Item bold>Cash: {data.money}⪽</Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          {/* Clothing booth item list */}
          <Stack.Item grow={1}>
            <ClothingBoothStockList />
          </Stack.Item>
          {/* Character rendering and purchase button. */}
          <Stack.Item>
            <Stack>
              <Stack.Item align="center">
                <Section fill>
                  <CharacterPreview />
                </Section>
              </Stack.Item>
              <Stack.Item grow={1}>
                <Section fill>
                  <Stack fill vertical justify="space-around">
                    <Stack.Item>
                      <PurchaseInfo />
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const ClothingBoothStockList = (_, context) => {
  const { data } = useBackend<ClothingBoothData>(context);
  const [slotFilters] = useLocalState(context, 'slotFilters', {});
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');

  const stockInformationList = Object.values(data.clothingBoothStockInformation);
  const slotFilteredStockInformationList = Object.values(slotFilters).length
    ? stockInformationList.filter((stockItem) => slotFilters[stockItem.slot])
    : stockInformationList;
  const searchFilteredStockInformationList = searchText
    ? slotFilteredStockInformationList.filter((stockItem) =>
      stockItem.name.toLowerCase().includes(searchText.toLowerCase())
    )
    : slotFilteredStockInformationList;

  return (
    <Stack fill>
      <Stack.Item>
        <ClothingBoothSlotFilters />
      </Stack.Item>
      <Stack.Item grow>
        <Stack fill vertical>
          <Stack.Item>
            <Section>
              <Stack fluid align="center" justify="space-between">
                <Stack.Item grow>
                  <Input fluid onInput={(e, value) => setSearchText(value)} placeholder="Search by name..." />
                </Stack.Item>
                <Stack.Item>
                  <Dropdown className="clothingbooth__dropdown" selected="A -> Z" />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable>
              {searchFilteredStockInformationList.map((stockItem) => (
                <ClothingBoothItem key={stockItem.name} {...stockItem} />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const ClothingBoothSlotFilters = (props, context) => {
  const [slotFilters, setSlotFilters] = useLocalState(context, 'slotFilters', {});
  const toggleSlotFilter = (filter: number) =>
    setSlotFilters({
      ...slotFilters,
      [filter]: !slotFilters[filter],
    });

  return (
    <Section fill>
      <Stack fill vertical>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Mask]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Mask)}>
            Mask
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Glasses]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Glasses)}>
            Glasses
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Gloves]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Gloves)}>
            Gloves
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Headwear]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Headwear)}>
            Headwear
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Shoes]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Shoes)}>
            Shoes
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Suit]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Suit)}>
            Suit
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!slotFilters[ClothingBoothSlotKeys.Uniform]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Uniform)}>
            Uniform
          </Button.Checkbox>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ClothingBoothItem = (props: ClothingBoothItemInformationProps, context) => {
  const { act, data } = useBackend<ClothingBoothData>(context);

  return (
    <>
      <Stack align="center" className={classes(['clothingbooth__boothitem'])}>
        <Stack.Item>
          <Image pixelated src={`data:image/png;base64,${props.image}`} />
        </Stack.Item>
        <Stack.Item grow={1}>
          <Stack fill vertical>
            <Stack.Item bold>
              {capitalize(props.name)}
            </Stack.Item>
            {props.variantCount > 1 && (
              <Stack.Item italic>
                {props.variantCount} variants
              </Stack.Item>
            )}
          </Stack>
        </Stack.Item>
        <Stack.Item bold>
          {props.costMax !== props.costMin ? `${props.costMin}⪽ - ${props.costMax}⪽` : `${props.costMin}⪽`}
        </Stack.Item>
      </Stack>
      <Divider />
    </>
  );
};

const CharacterPreview = (_, context) => {
  const { act, data } = useBackend<ClothingBoothData>(context);
  return (
    <Stack vertical align="center">
      <Stack.Item textAlign>
        <Image height={data.previewHeight * 2 + 'px'} pixelated src={`data:image/png;base64,${data.previewIcon}`} />
      </Stack.Item>
      <Stack.Item>
        <Button icon="chevron-left" tooltip="Clockwise" tooltipPosition="right" onClick={() => act('rotate-cw')} />
        <Button
          icon="chevron-right"
          tooltip="Counter-clockwise"
          tooltipPosition="right"
          onClick={() => act('rotate-ccw')}
        />
      </Stack.Item>
    </Stack>
  );
};

const PurchaseInfo = (_, context) => {
  const { act, data } = useBackend<ClothingBoothData>(context);
  return (
    <Stack bold vertical textAlign="center">
      {data.selectedItemName ? (
        <>
          <Stack.Item>{`Selected: ${data.selectedItemName}`}</Stack.Item>
          <Stack.Item>{`Price: ${data.selectedItemCost}⪽`}</Stack.Item>
          <Stack.Item>
            <Button color="green" disabled={data.selectedItemCost > data.money} onClick={() => act('purchase')}>
              {!(data.selectedItemCost > data.money) ? `Purchase` : `Insufficient Cash`}
            </Button>
          </Stack.Item>
        </>
      ) : (
        <Stack.Item>{`Please select an item.`}</Stack.Item>
      )}
    </Stack>
  );
};
