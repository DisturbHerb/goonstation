/**
 * @file
 * @copyright 2023
 * @author DisturbHerb (https://github.com/disturbherb)
 * @license ISC
 */

import { Window } from '../../layouts';
import { AnimatedNumber, Box, Button, Dimmer, Icon, Section, Stack } from '../../components';
import { useBackend } from '../../backend';
import { getTemperatureIcon } from './../common/temperatureUtils';
import { NoContainer, ReagentGraph, ReagentList } from './../common/ReagentInfo';
import { capitalize } from './../common/stringUtils';
import { IceCreamData, FlavorArray } from './types';

export const IceCream = (_, context) => {
  const { act, data } = useBackend<IceCreamData>(context);

  return (
    <Window title={data.name} width={350} height={350}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section
              fill
              buttons={
                <Button icon="eject" onClick={() => act(data.cone ? 'eject_cone' : 'insert_cone')}>
                  {data.cone ? 'Eject Cone' : 'Insert Cone'}
                </Button>
              }
              title="Flavor Selection">
              <Stack>
                {data.flavors.map((flavor) => (
                  <Flavor key={flavor.flavorName} {...flavor} />
                ))}
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <InsertedContainer />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const Flavor = (props: FlavorArray, context) => {
  const { act, data } = useBackend<IceCreamData>(context);

  return (
    <Stack.Item width="50%">
      <Button fluid disabled={!data.cone} onClick={() => act('dispense_flavor', { flavor: props.flavorName })}>
        <Icon
          color={'rgba(' + props.flavorColor + ', 1)'}
          name="circle"
          pt={1}
          style={{
            'text-shadow': '0 0 3px #000',
          }}
        />
        {capitalize(props.flavorName)}
      </Button>
    </Stack.Item>
  );
};

const InsertedContainer = (_, context) => {
  const { act, data } = useBackend<IceCreamData>(context);
  const containerData = data.containerData ?? NoContainer;

  return (
    <Section fill>
      <Stack fill vertical>
        <Stack.Item>
          {!!data.containerData && (
            <Stack align="end" justify="space-between">
              <Stack.Item>
                <Button
                  onClick={() => act('dispense_flavor', { flavor: 'beaker' })}
                  style={{ overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>
                  <Icon
                    color={containerData.finalColor}
                    name="circle"
                    pt={1}
                    style={{
                      'text-shadow': '0 0 3px #000',
                    }}
                  />
                  {capitalize(containerData.name)}
                </Button>
              </Stack.Item>
              <Stack.Item align="end">
                <Button onClick={() => act('eject_beaker')} icon="eject" disabled={!data.containerData}>
                  Eject
                </Button>
              </Stack.Item>
            </Stack>
          )}
        </Stack.Item>
        <Stack.Item grow>
          <ReagentGraph container={containerData} />
          <ReagentList container={containerData} />
          <Box className="ChemHeater__TemperatureBox" textAlign="center">
            {!!containerData.totalVolume && (
              <Box fontSize={2} className={'ChemHeater__TemperatureNumber'}>
                <Icon name={getTemperatureIcon(containerData.temperature)} pr={0.25} />
                <AnimatedNumber value={containerData.temperature} /> K
              </Box>
            )}
          </Box>
          {!data.containerData && (
            <Dimmer>
              <Button icon="eject" fontSize={1.5} onClick={() => act('insert_beaker')} bold>
                Insert Container
              </Button>
            </Dimmer>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};
