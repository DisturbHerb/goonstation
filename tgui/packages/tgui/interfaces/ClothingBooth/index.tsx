/**
 * @file
 * @copyright 2023
 * @author DisturbHerb (https://github.com/disturbherb)
 * @license ISC
 */

import { classes } from 'common/react';
import { useBackend, useLocalState } from '../../backend';
import { Box, Button, Divider, Dropdown, Image, Input, Section, Stack } from '../../components';
import { Window } from '../../layouts';
import {
  ClothingBoothData,
  ClothingBoothItemInformationProps,
  ClothingBoothSlotKeys,
  ClothingBoothSortType,
  ItemVariantProps,
} from './type';

import { capitalize } from '../common/stringUtils';

export const ClothingBooth = (_, context) => {
  const { data } = useBackend<ClothingBoothData>(context);
  const [hideUnaffordable, toggleHideUnaffordable] = useLocalState(context, 'hideUnaffordable', false);

  return (
    <Window title={data.name} width={450} height={550}>
      <Window.Content>
        <Stack fill vertical>
          {/* Topmost section, containing the cash balance. */}
          <Stack.Item>
            <Section fill>
              <Stack fluid align="center" justify="space-between">
                <Stack.Item bold>Cash: {data.money}⪽</Stack.Item>
                <Stack.Item>
                  <Button.Checkbox
                    checked={!!hideUnaffordable}
                    onClick={() => toggleHideUnaffordable(!hideUnaffordable)}>
                    Hide Unaffordable
                  </Button.Checkbox>
                </Stack.Item>
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

// Comparator functions courtesy of @mordent-goonstation.
type ComparatorFn<T> = (a: T, b: T) => number;
const stringComparator = (a: string, b: string) => (a ?? '').localeCompare(b ?? '');
const numberComparator = (a: number, b: number) => a - b;

const buildFieldComparator
  = <T, V>(fieldFn: (stockItem: T) => V, comparatorFn: ComparatorFn<V>) =>
    (a: T, b: T) =>
      comparatorFn(fieldFn(a), fieldFn(b));

const clothingBoothItemComparators: Record<ClothingBoothSortType, ComparatorFn<ClothingBoothItemInformationProps>> = {
  [ClothingBoothSortType.Name]: buildFieldComparator((stockItem) => stockItem.name, stringComparator),
  [ClothingBoothSortType.Price]: buildFieldComparator((stockItem) => stockItem.costMin, numberComparator),
  [ClothingBoothSortType.Season]: buildFieldComparator((stockItem) => stockItem.season, stringComparator),
};

const ClothingBoothStockList = (_, context) => {
  const { data } = useBackend<ClothingBoothData>(context);
  const [hideUnaffordable] = useLocalState(context, 'hideUnaffordable', false);
  const [slotFilters] = useLocalState(context, 'slotFilters', {});
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [sortType, setSortType] = useLocalState(context, 'sortType', ClothingBoothSortType.Name);
  const [sortAscending, toggleSortAscending] = useLocalState(context, 'sortAscending', true);

  const getSortComparator
    = (usedSortType: ClothingBoothSortType, usedSortDirection: boolean) =>
      (a: ClothingBoothItemInformationProps, b: ClothingBoothItemInformationProps) =>
        clothingBoothItemComparators[usedSortType](a, b) * (usedSortDirection ? 1 : -1);

  const stockInformationList = Object.values(data.clothingBoothStockInformation);
  const affordableFilteredStockInformationList = hideUnaffordable
    ? stockInformationList.filter((stockItem) => data.money >= stockItem.costMin)
    : stockInformationList;
  const slotFilteredStockInformationList = Object.values(slotFilters).some((filter) => filter === true)
    ? affordableFilteredStockInformationList.filter((stockItem) => slotFilters[stockItem.slot])
    : affordableFilteredStockInformationList;
  const searchFilteredStockInformationList = searchText
    ? slotFilteredStockInformationList.filter((stockItem) =>
      stockItem.name.toLowerCase().includes(searchText.toLowerCase())
    )
    : slotFilteredStockInformationList;
  const sortedStockInformationList = searchFilteredStockInformationList.sort(
    getSortComparator(sortType, sortAscending)
  );
  const seasonSortedStockInformationList = sortedStockInformationList.sort(
    getSortComparator(ClothingBoothSortType.Season, false)
  );

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
                <Stack.Item grow>
                  <Dropdown
                    noscroll
                    className="clothingbooth__dropdown"
                    displayText={`Sort: ${sortType}`}
                    onSelected={(value) => setSortType(value)}
                    options={[ClothingBoothSortType.Name, ClothingBoothSortType.Price]}
                    selected={sortType}
                    width="100%"
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon={sortAscending ? 'arrow-down-short-wide' : 'arrow-down-wide-short'}
                    onClick={() => toggleSortAscending(!sortAscending)}
                    tooltip={`Sort Direction: ${sortAscending ? 'Ascending' : 'Descending'}`}
                  />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable>
              {seasonSortedStockInformationList.map((stockItem) => (
                <ClothingBoothItem key={stockItem.name} {...stockItem} />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const ClothingBoothSlotFilters = (_, context) => {
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
          <Button color="transparent" onClick={() => setSlotFilters({})}>
            Clear Filters
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={!!slotFilters[ClothingBoothSlotKeys.Mask]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Mask)}>
            Mask
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={!!slotFilters[ClothingBoothSlotKeys.Glasses]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Glasses)}>
            Glasses
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={!!slotFilters[ClothingBoothSlotKeys.Gloves]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Gloves)}>
            Gloves
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={!!slotFilters[ClothingBoothSlotKeys.Headwear]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Headwear)}>
            Headwear
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={!!slotFilters[ClothingBoothSlotKeys.Shoes]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Shoes)}>
            Shoes
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={!!slotFilters[ClothingBoothSlotKeys.Suit]}
            onClick={() => toggleSlotFilter(ClothingBoothSlotKeys.Suit)}>
            Suit
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            fluid
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
      <Stack
        align="center"
        className={classes([
          'clothingbooth__boothitem',
          // selectedItem.name === props.name && 'clothingbooth__boothitem-selected',
        ])}
        onClick={() =>
          data.selectedItemName !== props.name
          && act('select-item', { name: props.name, variantName: props.initialVariant })}>
        <Stack.Item>
          <Image pixelated src={`data:image/png;base64,${props.image}`} />
        </Stack.Item>
        <Stack.Item grow={1}>
          <Stack fill vertical>
            <Stack.Item bold>{capitalize(props.name)}</Stack.Item>
            {props.season ? (
              <Stack.Item italic className={props.season && `clothingbooth__boothitem__season-${props.season}`}>
                {capitalize(props.season)} Collection
              </Stack.Item>
            ) : (
              ''
            )}
            {props.variantCount > 1 && <Stack.Item italic>{props.variantCount} variants</Stack.Item>}
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
        <Button icon="rotate-right" tooltip="Clockwise" tooltipPosition="bottom" onClick={() => act('rotate-cw')} />
        <Button
          icon="rotate-left"
          tooltip="Counter-clockwise"
          tooltipPosition="bottom"
          onClick={() => act('rotate-ccw')}
        />
      </Stack.Item>
      <Stack.Item>
        <Button.Checkbox checked={data.showClothing} color="transparent" onClick={() => act('toggle-clothing')}>
          Show Clothing
        </Button.Checkbox>
      </Stack.Item>
    </Stack>
  );
};

const PurchaseInfo = (_, context) => {
  const { act, data } = useBackend<ClothingBoothData>(context);
  return (
    <Stack bold vertical textAlign="center">
      {data.selectedItem ? (
        <>
          <Stack.Item>{`Selected: ${data.selectedItemName}`}</Stack.Item>
          {!!data.selectedItem && (
            <Stack.Item>
              {Object.values(data.selectedItem).map((variant) => (
                <VariantSwatch key={variant.name} {...variant} />
              ))}
            </Stack.Item>
          )}
          <Stack.Item>
            <Button color="green" disabled={data.selectedItemCost > data.money} onClick={() => act('purchase')}>
              {!(data.selectedItemCost > data.money) ? `Purchase (${data.selectedItemCost}⪽)` : `Insufficient Cash`}
            </Button>
          </Stack.Item>
        </>
      ) : (
        <Stack.Item>{`Please select an item.`}</Stack.Item>
      )}
    </Stack>
  );
};

const VariantSwatch = (props: ItemVariantProps, context) => {
  return <Box />;
};
