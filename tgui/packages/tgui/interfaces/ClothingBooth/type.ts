import { Color } from "../../../common/color";

export interface ClothingBoothData {
  clothingBoothStockInformation: ClothingBoothItemInformationProps[];
  money: number;
  name: string;
  previewHeight: number;
  previewIcon: string;
  selectedItem: ClothingBoothSelectedItemProps[];
  selectedItemCost: number;
  selectedItemName: string;
}

export interface ClothingBoothItemInformationProps {
  costMax: number;
  costMin: number;
  image: string;
  key: any;
  name: string;
  season: string;
  slot: number;
  variantCount: number;
}

export interface ClothingBoothSelectedItemProps {
  name: string;
  season: string;
  slot: number;
  variants: ItemVariantProps[];
}

export interface ItemVariantProps {
  variantName: string;
  variantColor: Color;
  details: VariantDetailsProps[];
  cost: number;
  itemPath: string;
}

export interface VariantDetailsProps {
  detailName: string;
  detailColor: Color;
  cost: number;
  itemPath: string;
}

export enum ClothingBoothSlotKeys {
  Mask = 2,
  Glasses = 9,
  Gloves = 10,
  Headwear = 11,
  Shoes = 12,
  Suit = 13,
  Uniform = 14,
}

export enum ClothingBoothSortType {
  Name = "Name",
  Price = "Price",
  Season = "Season",
}

export enum ClothingBoothSortComparatorType {
  String,
  Number,
}
