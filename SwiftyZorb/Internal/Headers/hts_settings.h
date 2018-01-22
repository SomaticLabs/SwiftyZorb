//
//  hts_settings.h
//  SwiftyZorb
//
//  Created by Jacob Rockland on 9/15/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

/** @file
 *
 * @brief Implementation of data structures for the HTS Settings characteristic
 *
 */


#ifndef HTS_Settings_h
#define HTS_Settings_h

#include <stdint.h>

/** The Haptic Timeline Service settings structure that holds user-specified
 * preferences.
 */
typedef struct hts_settings {
    uint8_t wrist_orientation; ///< Orientation respective to the user's wrist - 0 corresponds to left, 1 corresponds to right
    uint8_t pair_button_orientation; ///< Orientation respective to the pair button - 0 corresponds to left, 1 corresponds to right
    uint8_t intensity_level; ///< Intensity setting for haptic effects - 0 corresponds to low, 1 corresponds to medium, 2 corresponds to high
} hts_settings;

typedef union hts_settings_data {
    uint8_t bytes[sizeof(hts_settings)]; ///< Array of bytes for incoming BLE transmissions
    hts_settings data; ///< The Settings structure consisting of 2 bytes
} hts_settings_data;

#endif /* HTS_Settings_h */

