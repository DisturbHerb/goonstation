import { ReagentContainer } from "./../common/ReagentInfo";

export interface IceCreamData {
  cone: boolean;
  containerData: ReagentContainer | null;
  flavors: FlavorArray[];
  name: string;
}

export interface FlavorArray {
  flavorName: string;
  flavorColor: string;
  key: string;
}
