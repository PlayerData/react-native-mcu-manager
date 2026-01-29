import {
  withGradleProperties,
  ConfigPlugin,
} from '@expo/config-plugins';
import { ExpoConfig } from '@expo/config-types';

/**
 * A Config Plugin to modify android/gradle.properties.
 */
const withCustomGradleProps: ConfigPlugin<ExpoConfig> = (config) => {
  return withGradleProperties(config, (config) => {
    const gradleProperties = config.modResults;

    gradleProperties.push(
      { type: 'property', key: 'org.gradle.parallel', value: 'true' },
      { type: 'property', key: 'org.gradle.daemon', value: 'true' },
      {
        type: 'property',
        key: 'org.gradle.jvmargs',
        value: '-Xmx4g -Dfile.encoding=UTF-8',
      },
      { type: 'property', key: 'org.gradle.configureondemand', value: 'true' }
    );

    return config;
  });
};

export default withCustomGradleProps;
