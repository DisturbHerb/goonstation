import { useBackend } from '../../backend';
import { Button, Flex, Stack } from '../../components';
import type { ClothingBoothData, ClothingBoothItemData, ClothingBoothSlotKey } from './type';
import { GroupingTagContainer as GroupingTagContainer } from './GroupingTag';
import { ItemSwatch as ItemSwatch } from './ItemSwatch';

export const PurchaseInfo = (_, context) => {
  const { act, data } = useBackend<ClothingBoothData>(context);
  const { catalogue, accountBalance, cash, selectedGroupingName, selectedItemName } = data;

  const selectedGrouping = catalogue[selectedGroupingName];
  let selectedGroupingSlot: ClothingBoothSlotKey | undefined;
  let selectedGroupingTags: string[] | undefined;
  let selectedItem: ClothingBoothItemData | undefined;
  if (selectedGrouping) {
    selectedGroupingSlot = selectedGrouping.slot;
    selectedGroupingTags = selectedGrouping.grouping_tags;
    selectedItem = selectedGrouping.clothingbooth_items[selectedItemName];
  }

  const handlePurchase = () => act('purchase');
  const handleSelectItem = (name: string) => act('select-item', { name });

  return (
    <Stack vertical textAlign="center">
      {selectedItemName ? (
        <>
          <Stack.Item bold>
            <Stack align="center" justify="center">
              <Stack.Item>
                {selectedGroupingName}
              </Stack.Item>
            </Stack>
          </Stack.Item>
          {Object.values(selectedGroupingTags).length && (
            <Stack.Item>
              <Stack justify="center">
                <Stack.Item bold>Tags: </Stack.Item>
                <Stack.Item style={{ opacity: '0.5' }}>
                  <GroupingTagContainer slot={selectedGroupingSlot} grouping_tags={selectedGroupingTags} />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          )}
          <Stack.Item bold>Selected: {selectedItemName}</Stack.Item>
          {Object.values(selectedGrouping.clothingbooth_items).length > 1 && (
            <Stack.Item>
              <Flex justify="center" wrap="wrap">
                {Object.values(selectedGrouping.clothingbooth_items).map((item) => (
                  <Flex.Item key={item.name}>
                    <ItemSwatch
                      {...item}
                      selected={selectedItemName === item.name}
                      onSelect={() => handleSelectItem(item.name)}
                    />
                  </Flex.Item>
                ))}
              </Flex>
            </Stack.Item>
          )}
          <Stack.Item bold>
            <Button color="good" disabled={selectedItem.cost > cash + accountBalance} onClick={handlePurchase}>
              {`${selectedItem.cost > cash + accountBalance ? 'Insufficent Money' : 'Purchase'} (${selectedItem.cost}⪽)`}
            </Button>
          </Stack.Item>
        </>
      ) : (
        <Stack.Item bold>Please select an item.</Stack.Item>
      )}
    </Stack>
  );
};
